import AddressBook
import XCTest

class RecordUpdatesTests: XCTestCase {
  func testFindsNewRecord() {
    let newRecord: ABRecord = newPersonRecord(firstName: "Arnold", lastName: "Alpha")
    let recordUpdates = RecordUpdates.collectFor([], from: [newRecord])

    XCTAssertEqual(recordUpdates.newRecords.count, 1)
    XCTAssertEqual(recordUpdates.changeSets.count, 0)
  }

  private func newPersonRecord(#firstName: String, lastName: String) -> ABRecord {
    let record: ABRecord = ABPersonCreate().takeRetainedValue()
    Records.setValue(firstName, toProperty: kABPersonFirstNameProperty, ofRecord: record)
    Records.setValue(lastName, toProperty: kABPersonLastNameProperty, ofRecord: record)
    return record
  }
}
