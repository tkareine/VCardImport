import AddressBook
import XCTest

class RecordUpdatesTests: XCTestCase {
  func testFindsNewRecord() {
    let newRecord: ABRecord = newPersonRecord(firstName: "Arnold", lastName: "Alpha")
    let recordUpdates = RecordUpdates.collectFor([], from: [newRecord])

    XCTAssertEqual(recordUpdates.newRecords.count, 1)
    XCTAssertEqual(recordUpdates.changeSets.count, 0)
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
    let recordUpdates = RecordUpdates.collectFor([existingRecord], from: [newRecord])

    XCTAssertEqual(recordUpdates.newRecords.count, 0)
    XCTAssertEqual(recordUpdates.changeSets.count, 0)
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
    let recordUpdates = RecordUpdates.collectFor([existingRecord], from: [newRecord])

    XCTAssertEqual(recordUpdates.newRecords.count, 0)
    XCTAssertEqual(recordUpdates.changeSets.count, 1)

    let changes = recordUpdates.changeSets.first!.multiValueChanges

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
