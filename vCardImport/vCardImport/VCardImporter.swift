import Foundation
import AddressBook

// TODO: Class without instance variables.
class VCardImporter {
  func importFrom(sources: [VCardSource], error: NSErrorPointer) -> Bool {
    var addressBookOpt: ABAddressBook? = newAddressBook(error)

    if addressBookOpt == nil {
      return false
    }

    let addressBook: ABAddressBook = addressBookOpt!

    if !authorizeAddressBookAccess(addressBook, error: error) {
      return false
    }

    let loadedRecords = loadExampleContacts()
    let existingRecords: [ABRecord] = ABAddressBookCopyArrayOfAllPeople(addressBook).takeRetainedValue()

    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: existingRecords,
      newRecords: loadedRecords)

    if !recordDiff.additions.isEmpty {
      let isSuccess = addRecords(recordDiff.additions, toAddressBook: addressBook, error: error)
      if !isSuccess {
        return false
      }
    }

    if !recordDiff.changes.isEmpty {
      let isSuccess = changeRecords(recordDiff.changes, error: error)
      if !isSuccess {
        return false
      }
    }

    if ABAddressBookHasUnsavedChanges(addressBook) {
      var abError: Unmanaged<CFError>?
      let isSaved = ABAddressBookSave(addressBook, &abError)

      if !isSaved {
        if error != nil && abError != nil {
          error.memory = Errors.fromCFError(abError!.takeRetainedValue())
        }
        return false
      }

      NSLog("Added %d contact(s), updated %d contact(s)",
        recordDiff.additions.count, recordDiff.changes.count)
    } else {
      NSLog("No contacts to add or update")
    }

    return true
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

  private func changeRecords(
    changeSets: [RecordChangeSet],
    error: NSErrorPointer)
    -> Bool
  {
    for changeSet in changeSets {
      for (property, value) in changeSet.singleValueChanges {
        let isChanged = Records.setValue(value, toProperty: property, ofRecord: changeSet.record)
        if !isChanged {
          setUpdateErrorIfErrorPointerGiven(
            property: property,
            record: changeSet.record,
            error: error)
          return false
        }
      }

      for (property, changes) in changeSet.multiValueChanges {
        let isChanged = Records.addValues(
          changes,
          toMultiValueProperty: property,
          ofRecord: changeSet.record)
        if !isChanged {
          setUpdateErrorIfErrorPointerGiven(
            property: property,
            record: changeSet.record,
            error: error)
          return false
        }
      }
    }

    return true
  }

  private func setUpdateErrorIfErrorPointerGiven(
    #property: ABPropertyID,
    record: ABRecord,
    error: NSErrorPointer)
  {
    if error != nil {
      error.memory = Errors.addressBookFailedToUpdateContact(
        name: ABRecordCopyCompositeName(record).takeRetainedValue(),
        property: property)
    }
  }

  private func loadExampleContacts() -> [ABRecord] {
    let vcardPath = NSBundle.mainBundle().pathForResource("example-contacts", ofType: "vcf")
    let vcardData = NSData(contentsOfFile: vcardPath!)
    return ABPersonCreatePeopleInSourceWithVCardRepresentation(nil, vcardData).takeRetainedValue()
  }
}
