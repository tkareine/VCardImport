import Foundation
import AddressBook

class VCardImporter {
  typealias OnSourceFailureCallback = (VCardSource, NSError) -> Void
  typealias OnSourceSuccessCallback = (VCardSource, (additions: Int, changes: Int)) -> Void
  typealias OnFailureCallback = NSError -> Void
  typealias OnSuccessCallback = () -> Void

  private let onSourceFailure: OnSourceFailureCallback
  private let onSourceSuccess: OnSourceSuccessCallback
  private let onFailure: OnFailureCallback
  private let onSuccess: OnSuccessCallback

  class func builder() -> Builder {
    return Builder()
  }

  private init(
    onSourceFailure: OnSourceFailureCallback,
    onSourceSuccess: OnSourceSuccessCallback,
    onFailure: OnFailureCallback,
    onSuccess: OnSuccessCallback)
  {
    self.onSourceFailure = onSourceFailure
    self.onSourceSuccess = onSourceSuccess
    self.onFailure = onFailure
    self.onSuccess = onSuccess
  }

  // The implementation is long and ugly, but I prefer to keep dispatching calls
  // to background jobs and back to the main thread in one place.
  func importFrom(sources: [VCardSource]) {
    BackgroundExecution.dispatchAsync {
      var error: NSError?
      var addressBookOpt: ABAddressBook? = self.newAddressBook(&error)

      if addressBookOpt == nil {
        BackgroundExecution.dispatchAsyncToMain { self.onFailure(error!) }
        return
      }

      let addressBook: ABAddressBook = addressBookOpt!

      if !self.authorizeAddressBookAccess(addressBook, error: &error) {
        BackgroundExecution.dispatchAsyncToMain { self.onFailure(error!) }
        return
      }

      let recordLoaders: [(VCardSource, Future<[ABRecord]>)] = sources.map { source in
        let recordLoader = self.loadRecordsFromURL(source.connection.url)
        return (source, recordLoader)
      }

      for (source, recordLoader) in recordLoaders {
        let loadingResult = recordLoader.get()

        if let failure = loadingResult as? Failure {
          BackgroundExecution.dispatchAsyncToMain {
            self.onSourceFailure(source, Errors.addressBookFailedToLoadVCardSource(failure.desc))
          }
          continue
        }

        let loadedRecords = loadingResult.value!
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
            BackgroundExecution.dispatchAsyncToMain { self.onSourceFailure(source, error!) }
            continue
          }
        }

        if !recordDiff.changes.isEmpty {
          let isSuccess = self.changeRecords(recordDiff.changes, error: &error)
          if !isSuccess {
            BackgroundExecution.dispatchAsyncToMain { self.onSourceFailure(source, error!) }
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
            BackgroundExecution.dispatchAsyncToMain { self.onSourceFailure(source, error!) }
            continue
          }

          BackgroundExecution.dispatchAsyncToMain {
            self.onSourceSuccess(
              source,
              (recordDiff.additions.count, recordDiff.changes.count))
          }
          NSLog("VCard source %@: added %d contact(s), updated %d contact(s)",
            source.name, recordDiff.additions.count, recordDiff.changes.count)
        } else {
          BackgroundExecution.dispatchAsyncToMain { self.onSourceSuccess(source, (0, 0)) }
          NSLog("VCard source %@: no contacts to add or update", source.name)
        }
      }

      BackgroundExecution.dispatchAsyncToMain(self.onSuccess)
    }
  }

  private func authorizeAddressBookAccess(
    addressBook: ABAddressBook,
    error: NSErrorPointer)
    -> Bool
  {
    var authStatus = ABAddressBookGetAuthorizationStatus()

    if authStatus == .NotDetermined {
      authStatus = requestAddressBookAuthorizationAndWaitResult(addressBook)
    }

    if authStatus != .Authorized {
      if error != nil {
        error.memory = Errors.addressBookAccessDeniedOrResticted()
      }

      return false
    }

    return true
  }

  private func requestAddressBookAuthorizationAndWaitResult(
    addressBook: ABAddressBook)
    -> ABAuthorizationStatus
  {
    var authResolution = false
    let semaphore = dispatch_semaphore_create(0)

    ABAddressBookRequestAccessWithCompletion(addressBook) { isGranted, _error in
      authResolution = isGranted
      dispatch_semaphore_signal(semaphore)
    }

    let timeout = dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) * Int64(30))
    dispatch_semaphore_wait(semaphore, timeout)

    return authResolution ? .Authorized : .Denied
  }

  private func newAddressBook(error: NSErrorPointer) -> ABAddressBook? {
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
        let isChanged = Records.setValue(value, toProperty: property, ofRecord: changeSet.record)
        if !isChanged {
          setRecordChangeError(property: property, record: changeSet.record, error: error)
          return false
        }
      }

      for (property, changes) in changeSet.multiValueChanges {
        let isChanged = Records.addValues(
          changes,
          toMultiValueProperty: property,
          ofRecord: changeSet.record)
        if !isChanged {
          setRecordChangeError(property: property, record: changeSet.record, error: error)
          return false
        }
      }
    }

    return true
  }

  private func setRecordChangeError(
    #property: ABPropertyID,
    record: ABRecord,
    error: NSErrorPointer)
  {
    error.memory = Errors.addressBookFailedToChangeRecord(
      name: ABRecordCopyCompositeName(record).takeRetainedValue(),
      property: property)
  }

  private func loadRecordsFromURL(url: NSURL) -> Future<[ABRecord]> {
    let fileURL = Files.tempFile()
    let future = URLConnection
        .download(url, toDestination: fileURL)
        .flatMap(loadRecordsFromFile)
    future.onComplete { _ in Files.removeFile(fileURL) }
    return future
  }

  private func loadRecordsFromFile(fileURL: NSURL) -> Future<[ABRecord]> {
    let vcardData = NSData(contentsOfURL: fileURL)
    if let records = ABPersonCreatePeopleInSourceWithVCardRepresentation(nil, vcardData) {
      return Future.succeeded(records.takeRetainedValue())
    } else {
      return Future.failed("invalid VCard file")
    }
  }

  class Builder {
    private var _onSourceFailure: OnSourceFailureCallback?
    private var _onSourceSuccess: OnSourceSuccessCallback?
    private var _onFailure: OnFailureCallback?
    private var _onSuccess: OnSuccessCallback?

    func onSourceFailure(callback: OnSourceFailureCallback) -> Builder {
      _onSourceFailure = callback
      return self
    }

    func onSourceSuccess(callback: OnSourceSuccessCallback) -> Builder {
      _onSourceSuccess = callback
      return self
    }

    func onFailure(callback: OnFailureCallback) -> Builder {
      _onFailure = callback
      return self
    }

    func onSuccess(callback: OnSuccessCallback) -> Builder {
      _onSuccess = callback
      return self
    }

    func build() -> VCardImporter {
      if _onSourceFailure == nil ||
        _onSourceSuccess == nil ||
        _onFailure == nil ||
        _onSuccess == nil {
        fatalError("all callbacks must be given")
      }
      return VCardImporter(
        onSourceFailure: _onSourceFailure!,
        onSourceSuccess: _onSourceSuccess!,
        onFailure: _onFailure!,
        onSuccess: _onSuccess!)
    }
  }
}
