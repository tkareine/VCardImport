import Foundation
import AddressBook

class VCardImporter {
  typealias OnSourceDownloadCallback = (VCardSource, URLConnection.ProgressBytes) -> Void
  typealias OnSourceCompleteCallback = (VCardSource, (additions: Int, changes: Int)?, ModifiedHeaderStamp?, NSError?) -> Void
  typealias OnCompleteCallback = NSError? -> Void

  private let onSourceDownload: OnSourceDownloadCallback
  private let onSourceComplete: OnSourceCompleteCallback
  private let onComplete: OnCompleteCallback
  private let urlConnection: URLConnection
  private let queue: QueueExecution.Queue

  class func builder() -> Builder {
    return Builder()
  }

  private init(
    onSourceDownload: OnSourceDownloadCallback,
    onSourceComplete: OnSourceCompleteCallback,
    onComplete: OnCompleteCallback,
    urlConnection: URLConnection,
    queue: QueueExecution.Queue)
  {
    self.onSourceDownload = onSourceDownload
    self.onSourceComplete = onSourceComplete
    self.onComplete = onComplete
    self.urlConnection = urlConnection
    self.queue = queue
  }

  func importFrom(sources: [VCardSource]) {
    // The implementation is long and ugly, but I prefer to keep dispatching
    // calls to background jobs and back to the user-specified queue in one
    // place.

    QueueExecution.async(QueueExecution.backgroundQueue) {
      var error: NSError?
      var addressBookOpt: ABAddressBook? = self.makeAddressBook(&error)

      if addressBookOpt == nil {
        QueueExecution.async(self.queue) { self.onComplete(error!) }
        return
      }

      let addressBook: ABAddressBook = addressBookOpt!

      let sourceImports: [(VCardSource, Future<SourceImportResult>)] = sources.map { source in
        (source, self.checkAndDownloadSource(source))
      }

      for (source, sourceImport) in sourceImports {
        let importResult = sourceImport.get()

        var loadedRecords: [ABRecord]
        var modifiedHeaderStamp: ModifiedHeaderStamp?

        switch importResult {
        case .Success(let res):
          switch res() {
          case .Unchanged:
            QueueExecution.async(self.queue) {
              self.onSourceComplete(source, (0, 0), nil, nil)
            }
            continue
          case .Updated(let records, let stamp):
            loadedRecords = records
            modifiedHeaderStamp = stamp
          }
        case .Failure(let desc):
          QueueExecution.async(self.queue) {
            self.onSourceComplete(source, nil, nil, Errors.addressBookFailedToLoadVCardSource(desc))
          }
          continue
        }

        let existingRecords: [ABRecord] = ABAddressBookCopyArrayOfAllPeople(addressBook).takeRetainedValue()

        let recordDiff = RecordDifferences.resolveBetween(
          oldRecords: existingRecords,
          newRecords: loadedRecords)

        if !recordDiff.additions.isEmpty {
          let isSuccess = self.addRecords(
            recordDiff.additions,
            toAddressBook: addressBook,
            error: &error)
          if !isSuccess {
            QueueExecution.async(self.queue) { self.onSourceComplete(source, nil, nil, error!) }
            continue
          }
        }

        if !recordDiff.changes.isEmpty {
          let isSuccess = self.changeRecords(recordDiff.changes, error: &error)
          if !isSuccess {
            QueueExecution.async(self.queue) { self.onSourceComplete(source, nil, nil, error!) }
            continue
          }
        }

        if ABAddressBookHasUnsavedChanges(addressBook) {
          var abError: Unmanaged<CFError>?
          let isSaved = ABAddressBookSave(addressBook, &abError)

          if !isSaved {
            if abError != nil {
              error = Errors.fromCFError(abError!.takeRetainedValue())
            }
            QueueExecution.async(self.queue) { self.onSourceComplete(source, nil, nil, error!) }
            continue
          }

          NSLog("vCard source %@: added %d contact(s), updated %d contact(s)",
            source.name, recordDiff.additions.count, recordDiff.changes.count)
          QueueExecution.async(self.queue) {
            self.onSourceComplete(
              source,
              (recordDiff.additions.count, recordDiff.changes.count),
              modifiedHeaderStamp,
              nil)
          }
        } else {
          NSLog("vCard source %@: no contacts to add or update", source.name)
          QueueExecution.async(self.queue) {
            self.onSourceComplete(source, (0, 0), modifiedHeaderStamp, nil)
          }
        }
      }

      QueueExecution.async(self.queue) { self.onComplete(nil) }
    }
  }

  private func makeAddressBook(error: NSErrorPointer) -> ABAddressBook? {
    func make() -> ABAddressBook? {
      var abError: Unmanaged<CFError>?
      let ab: Unmanaged<ABAddressBook>? = ABAddressBookCreateWithOptions(nil, &abError)

      if let abRef = ab {
        return abRef.takeRetainedValue()
      }

      if error != nil && abError != nil {
        error.memory = Errors.fromCFError(abError!.takeRetainedValue())
      }

      return nil
    }

    var authStatus = ABAddressBookGetAuthorizationStatus()
    var addressBook: ABAddressBook?

    if authStatus == .NotDetermined {
      if let ab: ABAddressBook = make() {
        addressBook = ab
        authStatus = requestAddressBookAuthorizationAndWaitResult(ab)
      }
    }

    if authStatus != .Authorized {
      if error != nil {
        error.memory = Errors.addressBookAccessDeniedOrRestricted()
      }

      return nil
    }

    if let ab: ABAddressBook = addressBook {
      return ab
    } else {
      return make()
    }
  }

  private func requestAddressBookAuthorizationAndWaitResult(
    addressBook: ABAddressBook)
    -> ABAuthorizationStatus
  {
    var authResolution = false
    let semaphore = Semaphore()

    ABAddressBookRequestAccessWithCompletion(addressBook) { isGranted, _error in
      authResolution = isGranted
      semaphore.signal()
    }

    semaphore.wait(timeout: 30_000)

    return authResolution ? .Authorized : .Denied
  }

  private func addRecords(
    records: [ABRecord],
    toAddressBook addressBook: ABAddressBook,
    error: NSErrorPointer)
    -> Bool
  {
    for record in records {
      var abError: Unmanaged<CFError>?

      let isAdded = ABAddressBookAddRecord(addressBook, record, &abError)

      if !isAdded {
        if error != nil && abError != nil {
          error.memory = Errors.fromCFError(abError!.takeRetainedValue())
        }

        return false
      }
    }

    return true
  }

  private func changeRecords(changeSets: [RecordChangeSet], error: NSErrorPointer) -> Bool {
    for changeSet in changeSets {
      for (property, value) in changeSet.singleValueChanges {
        let isChanged = Records.setValue(value, toSingleValueProperty: property, of: changeSet.record)
        if !isChanged {
          error.memory = Errors.addressBookFailedToChange(property, of: changeSet.record)
          return false
        }
      }

      for (property, changes) in changeSet.multiValueChanges {
        let isChanged = Records.addValues(
          changes,
          toMultiValueProperty: property,
          of: changeSet.record)
        if !isChanged {
          error.memory = Errors.addressBookFailedToChange(property, of: changeSet.record)
          return false
        }
      }

      if let img = changeSet.imageChange {
        let isChanged = Records.setImage(img, of: changeSet.record)
        if !isChanged {
          error.memory = Errors.addressBookFailedToChangeImage(of: changeSet.record)
          return false
        }
      }
    }

    return true
  }

  private func checkAndDownloadSource(source: VCardSource) -> Future<SourceImportResult> {
    NSLog("vCard source %@: checking if remote has changed…", source.name)
    return urlConnection
      .head(
        source.connection.toURL(),
        headers: Config.Net.VCardHTTPHeaders,
        credential: source.connection.toCredential(.ForSession))
      .flatMap { response in
        let newStamp = ModifiedHeaderStamp(headers: response.allHeaderFields)

        if let oldStamp = source.lastImportResult?.modifiedHeaderStamp {
          if oldStamp == newStamp {
            NSLog("vCard source %@: remote hasn't changed (\(oldStamp))", source.name)
            return Future.succeeded(.Unchanged)
          }
        }

        NSLog("vCard source %@: remote has changed (\(newStamp)), downloading…", source.name)
        return self.downloadSource(source).map { records in .Updated(records, newStamp) }
      }
  }

  private func downloadSource(source: VCardSource) -> Future<[ABRecord]> {
    let fileURL = Files.tempURL()
    let onProgressCallback: URLConnection.OnProgressCallback = { progressBytes in
      QueueExecution.async(QueueExecution.mainQueue) {
        self.onSourceDownload(source, progressBytes)
      }
    }
    let future = urlConnection
      .download(
        source.connection.toURL(),
        to: fileURL,
        headers: Config.Net.VCardHTTPHeaders,
        credential: source.connection.toCredential(.ForSession),
        onProgress: onProgressCallback)
      .flatMap(loadRecordsFromFile)
    future.onComplete { _ in Files.remove(fileURL) }
    return future
  }

  private func loadRecordsFromFile(fileURL: NSURL) -> Future<[ABRecord]> {
    let vcardData = NSData(contentsOfURL: fileURL)
    if let records = ABPersonCreatePeopleInSourceWithVCardRepresentation(nil, vcardData) {
      let foundRecords: [ABRecord] = records.takeRetainedValue()
      if foundRecords.isEmpty {
        return Future.failed("no contact data found from vCard file")
      } else {
        return Future.succeeded(foundRecords)
      }
    } else {
      return Future.failed("invalid vCard file")
    }
  }

  private enum SourceImportResult {
    case Unchanged
    case Updated([ABRecord], ModifiedHeaderStamp?)
  }

  class Builder {
    private var onSourceDownload: OnSourceDownloadCallback?
    private var onSourceComplete: OnSourceCompleteCallback?
    private var onComplete: OnCompleteCallback?
    private var urlConnection: URLConnection?
    private var queue: QueueExecution.Queue?

    func onSourceDownload(callback: OnSourceDownloadCallback) -> Builder {
      self.onSourceDownload = callback
      return self
    }

    func onSourceComplete(callback: OnSourceCompleteCallback) -> Builder {
      self.onSourceComplete = callback
      return self
    }

    func onComplete(callback: OnCompleteCallback) -> Builder {
      self.onComplete = callback
      return self
    }

    func connectWith(urlConnection: URLConnection) -> Builder {
      self.urlConnection = urlConnection
      return self
    }

    func queueTo(queue: QueueExecution.Queue) -> Builder {
      self.queue = queue
      return self
    }

    func build() -> VCardImporter {
      if self.onSourceDownload == nil ||
        self.onSourceComplete == nil ||
        self.onComplete == nil ||
        self.urlConnection == nil ||
        self.queue == nil {
        fatalError("all parameters must be given")
      }
      return VCardImporter(
        onSourceDownload: self.onSourceDownload!,
        onSourceComplete: self.onSourceComplete!,
        onComplete: self.onComplete!,
        urlConnection: self.urlConnection!,
        queue: self.queue!)
    }
  }
}
