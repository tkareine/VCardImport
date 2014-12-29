import Foundation
import AddressBook

class VCardImporter {
  typealias OnSourceErrorCallback = (VCardSource, NSError) -> Void
  typealias OnFailureCallback = NSError -> Void
  typealias OnSuccessCallback = () -> Void

  private let onSourceError: OnSourceErrorCallback
  private let onFailure: OnFailureCallback
  private let onSuccess: OnSuccessCallback

  class func builder() -> Builder {
    return Builder()
  }

  private init(
    onSourceError: OnSourceErrorCallback,
    onFailure: OnFailureCallback,
    onSuccess: OnSuccessCallback)
  {
    self.onSourceError = onSourceError
    self.onFailure = onFailure
    self.onSuccess = onSuccess
  }

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

      // TODO: Load multiple sources here, process them one-by-one in reduce
      let loadingResult = self.loadRecordsFromURL(sources.first!.connection.url).get()

      if let failure = loadingResult as? Failure {
        BackgroundExecution.dispatchAsyncToMain {
          self.onSourceError(sources.first!, Errors.addressBookFailedToLoadVCardSource(failure.desc))
        }
        return
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
          BackgroundExecution.dispatchAsyncToMain { self.onSourceError(sources.first!, error!) }
          return
        }
      }

      if !recordDiff.changes.isEmpty {
        let isSuccess = self.changeRecords(recordDiff.changes, error: &error)
        if !isSuccess {
          BackgroundExecution.dispatchAsyncToMain { self.onSourceError(sources.first!, error!) }
          return
        }
      }

      if ABAddressBookHasUnsavedChanges(addressBook) {
        var abError: Unmanaged<CFError>?
        let isSaved = ABAddressBookSave(addressBook, &abError)

        if !isSaved {
          if abError != nil {
            error = Errors.fromCFError(abError!.takeRetainedValue())
          }
          BackgroundExecution.dispatchAsyncToMain { self.onFailure(error!) }
          return
        }

        NSLog("Added %d contact(s), updated %d contact(s)",
          recordDiff.additions.count, recordDiff.changes.count)
      } else {
        NSLog("No contacts to add or update")
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

  private func loadExampleContacts() -> [ABRecord] {
    let vcardPath = NSBundle.mainBundle().pathForResource("example-contacts", ofType: "vcf")
    let vcardData = NSData(contentsOfFile: vcardPath!)
    return ABPersonCreatePeopleInSourceWithVCardRepresentation(nil, vcardData).takeRetainedValue()
  }

  class Builder {
    private var _onSourceError: OnSourceErrorCallback?
    private var _onFailure: OnFailureCallback?
    private var _onSuccess: OnSuccessCallback?

    func onSourceError(callback: OnSourceErrorCallback) -> Builder {
      _onSourceError = callback
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
      if _onSourceError == nil || _onFailure == nil || _onSuccess == nil {
        fatalError("all callbacks must be given")
      }
      return VCardImporter(
        onSourceError: _onSourceError!,
        onFailure: _onFailure!,
        onSuccess: _onSuccess!)
    }
  }
}
