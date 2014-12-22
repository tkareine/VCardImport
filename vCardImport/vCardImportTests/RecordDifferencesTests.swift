import AddressBook
import XCTest

class RecordDifferencesTests: XCTestCase {
  func testFindsRecordAddition() {
    let newRecord: ABRecord = newPersonRecord(firstName: "Arnold", lastName: "Alpha")
    let recordDiff = RecordDifferences.resolveBetween(oldRecords: [], newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 1)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testFindsRecordChangesInFieldValues() {
    let oldRecord: ABRecord = newPersonRecord(firstName: "Arnold", lastName: "Alpha")
    let newRecordHomeAddress = newAddress(
      street: "Suite 1173",
      zip: "95814",
      city: "Sacramento",
      state: "CA")
    let newRecord: ABRecord = newPersonRecord(
      firstName: "Arnold",
      middleName: "Big",
      lastName: "Alpha",
      jobTitle: "Manager",
      department: "Headquarters",
      organization: "State Council",
      phones: [(kABPersonPhoneMainLabel, "5551001002")],
      emails: [("Home", "arnold.alpha@example.com")],
      urls: [("Work", "https://exampleinc.com/")],
      addresses: [("Home", newRecordHomeAddress)]
    )
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 1)

    let singleValueChanges = recordDiff.changes.first!.singleValueChanges

    XCTAssertEqual(singleValueChanges.count, 4)

    let middleNameChange = singleValueChanges[kABPersonMiddleNameProperty]!

    XCTAssertEqual(middleNameChange, "Big")

    let jobTitleChange = singleValueChanges[kABPersonJobTitleProperty]!

    XCTAssertEqual(jobTitleChange, "Manager")

    let departmentChange = singleValueChanges[kABPersonDepartmentProperty]!

    XCTAssertEqual(departmentChange, "Headquarters")

    let organizationChange = singleValueChanges[kABPersonOrganizationProperty]!

    XCTAssertEqual(organizationChange, "State Council")

    let multiValueChanges = recordDiff.changes.first!.multiValueChanges

    XCTAssertEqual(multiValueChanges.count, 4)

    let phoneChanges = multiValueChanges[kABPersonPhoneProperty]!

    XCTAssertEqual(phoneChanges.count, 1)
    XCTAssertEqual(phoneChanges.first!.0, kABPersonPhoneMainLabel)
    XCTAssertEqual(phoneChanges.first!.1, "5551001002")

    let emailChanges = multiValueChanges[kABPersonEmailProperty]!

    XCTAssertEqual(emailChanges.count, 1)
    XCTAssertEqual(emailChanges.first!.0, "Home")
    XCTAssertEqual(emailChanges.first!.1, "arnold.alpha@example.com")

    let urlChanges = multiValueChanges[kABPersonURLProperty]!

    XCTAssertEqual(urlChanges.count, 1)
    XCTAssertEqual(urlChanges.first!.0, "Work")
    XCTAssertEqual(urlChanges.first!.1, "https://exampleinc.com/")

    let addressChanges = multiValueChanges[kABPersonAddressProperty]!

    XCTAssertEqual(addressChanges.count, 1)
    XCTAssertEqual(addressChanges.first!.0, "Home")
    XCTAssertEqual(addressChanges.first!.1, newRecordHomeAddress)
  }

  func testDeterminesExistingRecordsByFirstAndLastName() {
    let oldRecords = [
      newPersonRecord(firstName: "Arnold Alpha"),
      newPersonRecord(lastName: "Arnold Alpha"),
      newPersonRecord(lastName: "Alpha", organization: "Arnold"),
      newPersonRecord(lastName: "Alpha", department: "Arnold"),
      newPersonRecord(middleName: "Arnold", lastName: "Alpha")
    ]
    let newRecord: ABRecord = newPersonRecord(firstName: "Arnold", lastName: "Alpha")
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: oldRecords,
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 1)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSkipsRecordAdditionForRecordWithEmptyFirstAndLastName() {
    let newRecord: ABRecord = newPersonRecord(firstName: "", lastName: "")
    let recordDiff = RecordDifferences.resolveBetween(oldRecords: [], newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSkipsRecordChangeForRecordWithEmptyFirstAndLastName() {
    let oldRecord: ABRecord = newPersonRecord(firstName: "", lastName: "")
    let newRecord: ABRecord = newPersonRecord(firstName: "", lastName: "", jobTitle: "worker")
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testDoesNotFindRecordChangesForNonTrackedFieldValues() {
    let oldRecord: ABRecord = newPersonRecord(firstName: "Arnold", lastName: "Alpha")
    let newRecord: ABRecord = newPersonRecord(firstName: "Arnold", lastName: "Alpha")
    Records.setValue("a note", toProperty: kABPersonNoteProperty, ofRecord: newRecord)
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSkipsRecordChangeForMultipleRecordsHavingSameFirstAndLastName() {
    let oldRecords = [
      newPersonRecord(firstName: "Arnold", lastName: "Alpha"),
      newPersonRecord(firstName: "Arnold", lastName: "Alpha")
    ]
    let newRecord: ABRecord = newPersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      jobTitle: "worker")
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: oldRecords,
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testDoesNotFindRecordChangesIfValueExistsForSingleValueField() {
    let oldRecord: ABRecord = newPersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      jobTitle: "Manager")
    let newRecord: ABRecord = newPersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      jobTitle: "Governor")
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testDoesNotFindRecordChangeIfNoNewValueForMultiValueFieldOfString() {
    let oldRecord: ABRecord = newPersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      phones: [(kABPersonPhoneMobileLabel, "5551001001")])
    let newRecord: ABRecord = newPersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      phones: [(kABPersonPhoneMainLabel, "5551001001")])
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testFindsRecordChangeIfNewValueForMultiValueFieldOfString() {
    let oldRecord: ABRecord = newPersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      phones: [(kABPersonPhoneMobileLabel, "5551001001")])
    let newRecord: ABRecord = newPersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      phones: [(kABPersonPhoneMainLabel, "5551001002")])
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 1)

    let changes = recordDiff.changes.first!.multiValueChanges

    XCTAssertEqual(changes.count, 1)

    let (propertyChange, valueChanges) = changes.first!

    XCTAssertEqual(propertyChange, kABPersonPhoneProperty)
    XCTAssertEqual(valueChanges.count, 1)
    XCTAssertEqual(valueChanges.first!.0, kABPersonPhoneMainLabel)
    XCTAssertEqual(valueChanges.first!.1, "5551001002")
  }

  func testDoesNotFindRecordChangeIfNoNewValueForMultiValueFieldOfDictionary() {
    let addr = newAddress(street: "Street 1", zip: "00001", city: "City", state: "CA")
    let oldRecord: ABRecord = newPersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      addresses: [("Home", addr)])
    let newRecord: ABRecord = newPersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      addresses: [("Work", addr)])
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testFindsRecordChangeIfNewValueForMultiValueFieldOfDictionary() {
    let oldAddr = newAddress(street: "Street 1", zip: "00001", city: "City", state: "CA")
    let newAddr = newAddress(street: "Street 2", zip: "00001", city: "City", state: "CA")
    let oldRecord: ABRecord = newPersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      addresses: [("Home", oldAddr)])
    let newRecord: ABRecord = newPersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      addresses: [("Work", newAddr)])
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 1)

    let changes = recordDiff.changes.first!.multiValueChanges

    XCTAssertEqual(changes.count, 1)

    let (propertyChange, valueChanges) = changes.first!

    XCTAssertEqual(propertyChange, kABPersonAddressProperty)
    XCTAssertEqual(valueChanges.count, 1)
    XCTAssertEqual(valueChanges.first!.0, "Work")
    XCTAssertEqual(valueChanges.first!.1, newAddr)
  }

  func testLatterRecordChangeOverridesFormer() {
    let oldRecord: ABRecord = newPersonRecord(firstName: "Arnold", lastName: "Alpha")
    let newRecords = [
      newPersonRecord(firstName: "Arnold", lastName: "Alpha", jobTitle: "former"),
      newPersonRecord(firstName: "Arnold", lastName: "Alpha", jobTitle: "latter")
    ]
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: newRecords)

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 1)

    let jobTitleChange = recordDiff.changes.first!.singleValueChanges[kABPersonJobTitleProperty]!

    XCTAssertEqual(jobTitleChange, "latter")
  }

  private func newPersonRecord(
    firstName: NSString? = nil,
    middleName: NSString? = nil,
    lastName: NSString? = nil,
    jobTitle: NSString? = nil,
    department: NSString? = nil,
    organization: NSString? = nil,
    phones: [(NSString, NSString)]? = nil,
    emails: [(NSString, NSString)]? = nil,
    urls: [(NSString, NSString)]? = nil,
    addresses: [(NSString, NSDictionary)]? = nil)
    -> ABRecord
  {
    let record: ABRecord = ABPersonCreate().takeRetainedValue()
    if let val = firstName {
      Records.setValue(val, toProperty: kABPersonFirstNameProperty, ofRecord: record)
    }
    if let val = middleName {
      Records.setValue(val, toProperty: kABPersonMiddleNameProperty, ofRecord: record)
    }
    if let val = lastName {
      Records.setValue(val, toProperty: kABPersonLastNameProperty, ofRecord: record)
    }
    if let val = jobTitle {
      Records.setValue(val, toProperty: kABPersonJobTitleProperty, ofRecord: record)
    }
    if let val = department {
      Records.setValue(val, toProperty: kABPersonDepartmentProperty, ofRecord: record)
    }
    if let val = organization {
      Records.setValue(val, toProperty: kABPersonOrganizationProperty, ofRecord: record)
    }
    if let vals = phones {
      Records.addValues(vals, toMultiValueProperty: kABPersonPhoneProperty, ofRecord: record)
    }
    if let vals = emails {
      Records.addValues(vals, toMultiValueProperty: kABPersonEmailProperty, ofRecord: record)
    }
    if let vals = urls {
      Records.addValues(vals, toMultiValueProperty: kABPersonURLProperty, ofRecord: record)
    }
    if let vals = addresses {
      Records.addValues(vals, toMultiValueProperty: kABPersonAddressProperty, ofRecord: record)
    }
    return record
  }

  private func newAddress(
    #street: String,
    zip: String,
    city: String,
    state: String)
    -> [String: String]
  {
    return [
      kABPersonAddressStreetKey: street,
      kABPersonAddressZIPKey: zip,
      kABPersonAddressCityKey: city,
      kABPersonAddressStateKey: state
    ]
  }
}
