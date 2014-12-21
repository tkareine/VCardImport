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
    let existingRecord: ABRecord = newPersonRecord(firstName: "Arnold", lastName: "Alpha")
    let newRecord: ABRecord = newPersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      jobTitle: "Manager",
      phones: [(kABPersonPhoneMainLabel, "5551001002")],
      emails: [("Home", "arnold.alpha@example.com")],
      urls: [("Work", "https://exampleinc.com/")]
    )
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [existingRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 1)

    let singleValueChanges = recordDiff.changes.first!.singleValueChanges

    XCTAssertEqual(singleValueChanges.count, 1)

    let jobTitleChange = singleValueChanges[kABPersonJobTitleProperty]!
    XCTAssertEqual(jobTitleChange, "Manager")

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

  func testDoesNotFindRecordChangesForNonTrackedFieldValues() {
    let existingRecord: ABRecord = newPersonRecord(firstName: "Arnold", lastName: "Alpha")
    let newRecord: ABRecord = newPersonRecord(firstName: "Arnold", lastName: "Alpha")
    Records.setValue("a note", toProperty: kABPersonNoteProperty, ofRecord: newRecord)
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [existingRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testDoesNotFindRecordChangesIfValueExistsForSingleValueField() {
    let existingRecord: ABRecord = newPersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      jobTitle: "Manager")
    let newRecord: ABRecord = newPersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      jobTitle: "Governor")
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [existingRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testDoesNotFindRecordChangesIfNoNewValuesForMultiValueFields() {
    let existingRecord: ABRecord = newPersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      phones: [(kABPersonPhoneMobileLabel, "5551001001")])
    let newRecord: ABRecord = newPersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      phones: [(kABPersonPhoneMainLabel, "5551001001")])
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [existingRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testFindsRecordChangeIfNewValueForMultiValueField() {
    let existingRecord: ABRecord = newPersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      phones: [(kABPersonPhoneMobileLabel, "5551001001")])
    let newRecord: ABRecord = newPersonRecord(
      firstName: "Arnold",
      lastName: "Alpha",
      phones: [(kABPersonPhoneMainLabel, "5551001002")])
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [existingRecord],
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

  private func newPersonRecord(
    #firstName: String,
    lastName: String,
    jobTitle: String? = nil,
    phones: [(String, String)]? = nil,
    emails: [(String, String)]? = nil,
    urls: [(String, String)]? = nil)
    -> ABRecord
  {
    let record: ABRecord = ABPersonCreate().takeRetainedValue()
    Records.setValue(firstName, toProperty: kABPersonFirstNameProperty, ofRecord: record)
    Records.setValue(lastName, toProperty: kABPersonLastNameProperty, ofRecord: record)
    if let val = jobTitle {
      Records.setValue(val, toProperty: kABPersonJobTitleProperty, ofRecord: record)
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
