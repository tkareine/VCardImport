import AddressBook
import XCTest

class RecordDifferencesTests: XCTestCase {
  func testSetsRecordAddition() {
    let newRecord: ABRecord = makePersonRecord(firstName: "Arnold", lastName: "Alpha")
    let recordDiff = RecordDifferences.resolveBetween(oldRecords: [], newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 1)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSetsRecordChangesForFieldValues() {
    let oldRecord: ABRecord = makePersonRecord(firstName: "Arnold", lastName: "Alpha")
    let newRecordHomeAddress = makeAddress(
      street: "Suite 1173",
      zip: "95814",
      city: "Sacramento",
      state: "CA")
    let newRecord: ABRecord = makePersonRecord(
      prefixName: "Mr.",
      firstName: "Arnold",
      nickName: "Arnie",
      middleName: "Big",
      lastName: "Alpha",
      suffixName: "Senior",
      organization: "State Council",
      jobTitle: "Manager",
      department: "Headquarters",
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

    XCTAssertEqual(singleValueChanges.count, 7)

    let prefixNameChange = singleValueChanges[kABPersonPrefixProperty]!

    XCTAssertEqual(prefixNameChange, "Mr.")

    let nickNameChange = singleValueChanges[kABPersonNicknameProperty]!

    XCTAssertEqual(nickNameChange, "Arnie")

    let middleNameChange = singleValueChanges[kABPersonMiddleNameProperty]!

    XCTAssertEqual(middleNameChange, "Big")

    let suffixNameChange = singleValueChanges[kABPersonSuffixProperty]!

    XCTAssertEqual(suffixNameChange, "Senior")

    let organizationChange = singleValueChanges[kABPersonOrganizationProperty]!

    XCTAssertEqual(organizationChange, "State Council")

    let jobTitleChange = singleValueChanges[kABPersonJobTitleProperty]!

    XCTAssertEqual(jobTitleChange, "Manager")

    let departmentChange = singleValueChanges[kABPersonDepartmentProperty]!

    XCTAssertEqual(departmentChange, "Headquarters")

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

  func testDoesNotSetRecordChangeForNonTrackedFieldValue() {
    let oldRecord: ABRecord = makePersonRecord(firstName: "Arnold", lastName: "Alpha")
    let newRecord: ABRecord = makePersonRecord(firstName: "Arnold", lastName: "Alpha")
    Records.setValue("a note", toSingleValueProperty: kABPersonNoteProperty, of: newRecord)
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testDeterminesExistingRecordsByFirstAndLastName() {
    let oldRecords = [
      makePersonRecord(firstName: "Arnold Alpha"),
      makePersonRecord(lastName: "Arnold Alpha"),
      makePersonRecord(lastName: "Alpha", organization: "Arnold"),
      makePersonRecord(lastName: "Alpha", department: "Arnold"),
      makePersonRecord(middleName: "Arnold", lastName: "Alpha")
    ]
    let newRecord: ABRecord = makePersonRecord(firstName: "Arnold", lastName: "Alpha")
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: oldRecords,
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 1)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSkipsRecordAdditionForNewRecordWithEmptyFirstAndLastName() {
    let newRecord: ABRecord = makePersonRecord(firstName: "", lastName: "")
    let recordDiff = RecordDifferences.resolveBetween(oldRecords: [], newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSkipsRecordAdditionForMultipleNewRecordsWithSameName() {
    let newRecords = [
      makePersonRecord(firstName: "Arnold", lastName: "Alpha", jobTitle: "former"),
      makePersonRecord(firstName: "Arnold", lastName: "Alpha", jobTitle: "latter")
    ]
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [],
      newRecords: newRecords)

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSkipsRecordChangeForOldRecordWithEmptyFirstAndLastName() {
    let oldRecord: ABRecord = makePersonRecord(firstName: "", lastName: "")
    let newRecord: ABRecord = makePersonRecord(firstName: "", lastName: "", jobTitle: "worker")
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSkipsRecordChangeForMultipleOldRecordsHavingSameName() {
    let oldRecords = [
      makePersonRecord(firstName: "Arnold", lastName: "Alpha"),
      makePersonRecord(firstName: "Arnold", lastName: "Alpha")
    ]
    let newRecord: ABRecord = makePersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      jobTitle: "worker")
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: oldRecords,
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSkipsRecordChangeForMultipleNewRecordsHavingSameName() {
    let oldRecord: ABRecord = makePersonRecord(firstName: "Arnold", lastName: "Alpha")
    let newRecords = [
      makePersonRecord(firstName: "Arnold", lastName: "Alpha", jobTitle: "former"),
      makePersonRecord(firstName: "Arnold", lastName: "Alpha", jobTitle: "latter")
    ]
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: newRecords)

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testDoesNotSetRecordChangeForExistingValueOfSingleValueField() {
    let oldRecord: ABRecord = makePersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      jobTitle: "Manager")
    let newRecord: ABRecord = makePersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      jobTitle: "Governor")
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testDoesNotSetRecordChangeForExistingValueOfMultiStringValueField() {
    let oldRecord: ABRecord = makePersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      phones: [(kABPersonPhoneMobileLabel, "5551001001")])
    let newRecord: ABRecord = makePersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      phones: [(kABPersonPhoneMainLabel, "5551001001")])
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSetsRecordChangeForNewValueForMultiStringValueField() {
    let oldRecord: ABRecord = makePersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      phones: [(kABPersonPhoneMobileLabel, "5551001001")])
    let newRecord: ABRecord = makePersonRecord(
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

  func testDoesNotSetRecordChangeForExistingValueOfMultiDictionaryValueField() {
    let addr = makeAddress(street: "Street 1", zip: "00001", city: "City", state: "CA")
    let oldRecord: ABRecord = makePersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      addresses: [("Home", addr)])
    let newRecord: ABRecord = makePersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      addresses: [("Work", addr)])
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSetsRecordChangeForNewValueOfMultiDictionaryValueField() {
    let oldAddr = makeAddress(street: "Street 1", zip: "00001", city: "City", state: "CA")
    let newAddr = makeAddress(street: "Street 2", zip: "00001", city: "City", state: "CA")
    let oldRecord: ABRecord = makePersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      addresses: [("Home", oldAddr)])
    let newRecord: ABRecord = makePersonRecord(
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

  private func makePersonRecord(
    prefixName: NSString? = nil,
    firstName: NSString? = nil,
    nickName: NSString? = nil,
    middleName: NSString? = nil,
    lastName: NSString? = nil,
    suffixName: NSString? = nil,
    organization: NSString? = nil,
    jobTitle: NSString? = nil,
    department: NSString? = nil,
    phones: [(NSString, NSString)]? = nil,
    emails: [(NSString, NSString)]? = nil,
    urls: [(NSString, NSString)]? = nil,
    addresses: [(NSString, NSDictionary)]? = nil)
    -> ABRecord
  {
    let record: ABRecord = ABPersonCreate().takeRetainedValue()
    if let val = prefixName {
      Records.setValue(val, toSingleValueProperty: kABPersonPrefixProperty, of: record)
    }
    if let val = firstName {
      Records.setValue(val, toSingleValueProperty: kABPersonFirstNameProperty, of: record)
    }
    if let val = nickName {
      Records.setValue(val, toSingleValueProperty: kABPersonNicknameProperty, of: record)
    }
    if let val = middleName {
      Records.setValue(val, toSingleValueProperty: kABPersonMiddleNameProperty, of: record)
    }
    if let val = lastName {
      Records.setValue(val, toSingleValueProperty: kABPersonLastNameProperty, of: record)
    }
    if let val = suffixName {
      Records.setValue(val, toSingleValueProperty: kABPersonSuffixProperty, of: record)
    }
    if let val = organization {
      Records.setValue(val, toSingleValueProperty: kABPersonOrganizationProperty, of: record)
    }
    if let val = jobTitle {
      Records.setValue(val, toSingleValueProperty: kABPersonJobTitleProperty, of: record)
    }
    if let val = department {
      Records.setValue(val, toSingleValueProperty: kABPersonDepartmentProperty, of: record)
    }
    if let vals = phones {
      Records.addValues(vals, toMultiValueProperty: kABPersonPhoneProperty, of: record)
    }
    if let vals = emails {
      Records.addValues(vals, toMultiValueProperty: kABPersonEmailProperty, of: record)
    }
    if let vals = urls {
      Records.addValues(vals, toMultiValueProperty: kABPersonURLProperty, of: record)
    }
    if let vals = addresses {
      Records.addValues(vals, toMultiValueProperty: kABPersonAddressProperty, of: record)
    }
    return record
  }

  private func makeAddress(
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
