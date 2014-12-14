import Foundation
import AddressBook

class VCardImporter {
  func importFrom(sources: [VCardSource], error: NSErrorPointer) -> Bool {
    var addressBookOpt: ABAddressBook? = newAddressBook(error)

    if addressBookOpt == nil {
      return false
    }

    let addressBook: ABAddressBook = addressBookOpt!

    if (!authorizeAddressBookAccess(addressBook, error: error)) {
      return false
    }

    let loadedRecords = loadExampleContacts()
    let existingRecords: [ABRecord] = ABAddressBookCopyArrayOfAllPeople(addressBook).takeRetainedValue()

    let (newRecords, matchingRecords) = findNewAndMatchingRecords(
      loadedRecords,
      existing: existingRecords,
      error: error
    )

    let updateChangeSets = makeUpdateChangeSets(matching: matchingRecords, error: error)

    if !newRecords.isEmpty {
      let isSuccess = addRecords(newRecords, toAddressBook: addressBook, error: error)

      if !isSuccess {
        return false
      }
    }

    if !updateChangeSets.isEmpty {
      let isSuccess = updateRecords(
        matchingRecords,
        changes: updateChangeSets,
        toAddressBook: addressBook,
        error: error)

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

      NSLog("Added %d contact(s), updated %d contact(s)", newRecords.count, updateChangeSets.count)
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

  private func findNewAndMatchingRecords(
    loadedRecords: [ABRecord],
    existing existingRecords: [ABRecord],
    error: NSErrorPointer)
    -> ([ABRecord], [ContactName: (ABRecord, ABRecord)])
  {
    var newRecords: [ABRecord] = []
    var matchingRecordsByName: [ContactName: (ABRecord, ABRecord)] = [:]

    for loadedRecord in loadedRecords {
      let nameOfLoadedRecord = self.recordNameOf(loadedRecord)
      let existingRecordsWithName = existingRecords.filter { self.recordNameOf($0) == nameOfLoadedRecord }

      switch existingRecordsWithName.count {
      case 0:
        newRecords.append(loadedRecord)
      case 1:
        let existingRecord: ABRecord = existingRecordsWithName.first!
        let (firstName, lastName) = recordNameOf(existingRecord)
        let name = ContactName(firstName: firstName, lastName: lastName)
        matchingRecordsByName[name] = (existingRecord, loadedRecord)
      default:
        let (firstName, lastName) = recordNameOf(loadedRecord)
        NSLog("Skipping updating contact that has multiple records with the same name: %@, %@", lastName, firstName)
      }
    }

    return (newRecords, matchingRecordsByName)
  }

  private func recordNameOf(rec: ABRecord) -> (String, String) {
    let firstName = Contacts.getSingleValueProperty(kABPersonFirstNameProperty, ofRecord: rec)
    let lastName = Contacts.getSingleValueProperty(kABPersonLastNameProperty, ofRecord: rec)
    return (firstName, lastName)
  }

  private func makeUpdateChangeSets(
    matching matchingRecords: [ContactName: (ABRecord, ABRecord)],
    error: NSErrorPointer)
    -> [ContactChangeSet]
  {
    var changeSets: [ContactChangeSet] = []

    for (name, (existingRecord, loadedRecord)) in matchingRecords {
      let changeSet = ContactChangeSet.resolve(name, oldRecord: existingRecord, newRecord: loadedRecord)
      if let cs = changeSet {
        changeSets.append(cs)
      }
    }

    return changeSets
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

  private func updateRecords(
    matchingRecords: [ContactName: (ABRecord, ABRecord)],
    changes changeSets: [ContactChangeSet],
    toAddressBook addressBook: ABAddressBook,
    error: NSErrorPointer)
    -> Bool
  {
    for changeSet in changeSets {
      for (property, changes) in changeSet.multiValueChanges {
        let existingRecord: ABRecord = matchingRecords[changeSet.name]!.0
        let isUpdated = Contacts.addValues(
          changes,
          toMultiValueProperty: property,
          ofRecord: existingRecord)

        if !isUpdated {
          if error != nil {
            error.memory = Errors.addressBookFailedToUpdateContact(
              firstName: changeSet.name.firstName,
              lastName: changeSet.name.lastName,
              property: property)
          }
          return false
        }
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
