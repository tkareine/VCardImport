import Foundation
import AddressBook

class VCardImporter {
  func importFrom(urls: [NSURL], error: NSErrorPointer) -> Bool {
    if let addressBook: ABAddressBook = newAddressBook(error) {
      if (!authorizeAddressBookAccess(addressBook, error: error)) {
        return false
      }

      let newRecords = loadExampleContacts()
      let existingRecords: [ABRecord] = ABAddressBookCopyArrayOfAllPeople(addressBook).takeRetainedValue()

      let recordsToAdd = filterRecordsToAdd(newRecords, existing: existingRecords, error: error)

      let isImported = addRecords(recordsToAdd, toAddressBook: addressBook, error: error)

      if isImported {
        if ABAddressBookHasUnsavedChanges(addressBook) {
          var abError: Unmanaged<CFError>?
          let isSaved = ABAddressBookSave(addressBook, &abError)

          if isSaved {
            NSLog("Added %d contacts", recordsToAdd.count)
            return true
          }

          if error != nil && abError != nil {
            error.memory = Errors.fromCFError(abError!.takeRetainedValue())
          }
        } else {
          NSLog("No importable contacts")
          return true
        }
      }
    }

    return false
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

  private func filterRecordsToAdd(
    newRecords: [ABRecord],
    existing existingRecords: [ABRecord],
    error: NSErrorPointer) -> [ABRecord]
  {
    return newRecords.filter { newRecord in
      let nameOfNewRecord = self.recordNameOf(newRecord)
      return !existingRecords.any { self.recordNameOf($0) == nameOfNewRecord }
    }
  }

  private func recordNameOf(rec: ABRecord) -> (String, String) {
    let firstName = ABRecordCopyValue(rec, kABPersonFirstNameProperty).takeRetainedValue() as String
    let lastName = ABRecordCopyValue(rec, kABPersonLastNameProperty).takeRetainedValue() as String
    return (firstName, lastName)
  }

  private func addRecords(
    records: [ABRecord],
    toAddressBook addressBook: ABAddressBook,
    error: NSErrorPointer) -> Bool
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

  private func loadExampleContacts() -> [ABRecord] {
    let vcardPath = NSBundle.mainBundle().pathForResource("example-contacts", ofType: "vcf")
    let vcardData = NSData(contentsOfFile: vcardPath!)
    return ABPersonCreatePeopleInSourceWithVCardRepresentation(nil, vcardData).takeRetainedValue()
  }
}
