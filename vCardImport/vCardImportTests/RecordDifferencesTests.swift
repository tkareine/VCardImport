import AddressBook
import XCTest

class RecordDifferencesTests: XCTestCase {
  func testFindsNewRecord() {
    let newRecord: ABRecord = newPersonRecord(firstName: "Arnold", lastName: "Alpha")
    let recordDiff = RecordDifferences.resolveBetween(oldRecords: [], newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 1)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testDoesNotFindExistingRecordToUpdateIfNoNewFieldValues() {
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

  func testFindsExistingRecordToUpdateIfNewFieldValue() {
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
    phones: [(String, String)] = [])
    -> ABRecord
  {
    let record: ABRecord = ABPersonCreate().takeRetainedValue()
    Records.setValue(firstName, toProperty: kABPersonFirstNameProperty, ofRecord: record)
    Records.setValue(lastName, toProperty: kABPersonLastNameProperty, ofRecord: record)
    Records.addValues(phones, toMultiValueProperty: kABPersonPhoneProperty, ofRecord: record)
    return record
  }
}
