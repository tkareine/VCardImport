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
    let newRecord: ABRecord = newPersonRecord(
      firstName: "Arnold",
      middleName: "Big",
      lastName: "Alpha",
      jobTitle: "Manager",
      department: "Headquarters",
      organization: "State Council",
      phones: [(kABPersonPhoneMainLabel, "5551001002")],
      emails: [("Home", "arnold.alpha@example.com")],
      urls: [("Work", "https://exampleinc.com/")]
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

    XCTAssertEqual(multiValueChanges.count, 3)

    let phoneChanges = multiValueChanges[kABPersonPhoneProperty]!

    XCTAssertEqual(phoneChanges.count, 1)
    XCTAssert(phoneChanges.first! == (kABPersonPhoneMainLabel, "5551001002"))

    let emailChanges = multiValueChanges[kABPersonEmailProperty]!

    XCTAssertEqual(emailChanges.count, 1)
    XCTAssert(emailChanges.first! == ("Home", "arnold.alpha@example.com"))

    let urlChanges = multiValueChanges[kABPersonURLProperty]!

    XCTAssertEqual(urlChanges.count, 1)
    XCTAssert(urlChanges.first! == ("Work", "https://exampleinc.com/"))
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

  func testDoesNotFindRecordChangesIfNoNewValuesForMultiValueFields() {
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

  func testFindsRecordChangeIfNewValueForMultiValueField() {
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
    XCTAssert(valueChanges.first! == (kABPersonPhoneMainLabel, "5551001002"))
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
    firstName: String? = nil,
    middleName: String? = nil,
    lastName: String? = nil,
    jobTitle: String? = nil,
    department: String? = nil,
    organization: String? = nil,
    phones: [(String, String)]? = nil,
    emails: [(String, String)]? = nil,
    urls: [(String, String)]? = nil)
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
    return record
  }
}
