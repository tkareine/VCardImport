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

      let loadedRecords = self.loadRecordsFromURL(sources.first!.connection.url, error: &error)

      if loadedRecords == nil {
        BackgroundExecution.dispatchAsyncToMain { self.onSourceError(sources.first!, error!) }
        return
      }

      let existingRecords: [ABRecord] = ABAddressBookCopyArrayOfAllPeople(addressBook).takeRetainedValue()

      let recordDiff = RecordDifferences.resolveBetween(
        oldRecords: existingRecords,
        newRecords: loadedRecords!)

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

  // TODO
  private func loadRecordsFromURL(
    url: NSURL,
    error: NSErrorPointer)
    -> [ABRecord]?
  {
    let docDirURL = NSFileManager.defaultManager()
      .URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as NSURL
    let destinationURL = docDirURL.URLByAppendingPathComponent("download.vcf")
    NSFileManager.defaultManager().removeItemAtURL(destinationURL, error: nil)
    let sourceToLoad = URLConnection.download(url, toDestination: destinationURL)
    let result = sourceToLoad.get()
    if let failure = result as? Failure {
      error.memory = Errors.addressBookFailedToLoadVCardURL(failure.desc)
      return nil
    }
    let loadedRecords = loadRecordsFromFile(result.value!, error: error)
    if loadedRecords == nil {
      return nil
    }
    return loadedRecords!
  }

  private func loadRecordsFromFile(
    fileURL: NSURL,
    error: NSErrorPointer)
    -> [ABRecord]?
  {
    let vcardData = NSData(contentsOfURL: fileURL)
    if let records = ABPersonCreatePeopleInSourceWithVCardRepresentation(nil, vcardData) {
      return records.takeRetainedValue()
    } else {
      error.memory = Errors.addressBookFailedToLoadVCardFile()
      return nil
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
