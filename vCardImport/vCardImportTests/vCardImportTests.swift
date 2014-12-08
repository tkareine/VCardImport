import UIKit
import XCTest
import AddressBook

class vCardImportTests: XCTestCase {
  func testReadsRecordsFromVCard() {
    let vcardPath = NSBundle.mainBundle().pathForResource("example-contacts", ofType: "vcf")
    let vcardData = NSData(contentsOfFile: vcardPath!)
    let persons: [ABRecord] = ABPersonCreatePeopleInSourceWithVCardRepresentation(nil, vcardData).takeRetainedValue()

    let firstRecord: ABRecord = persons.first!
    assertPersonProperty(kABPersonFirstNameProperty, of: firstRecord, toEqual: "Arnold")
    assertPersonProperty(kABPersonLastNameProperty, of: firstRecord, toEqual: "Alpha")

    let secondRecord: ABRecord = persons[1]
    assertPersonProperty(kABPersonFirstNameProperty, of: secondRecord, toEqual: "Bert")
    assertPersonProperty(kABPersonLastNameProperty, of: secondRecord, toEqual: "Beta")
  }

  private func assertPersonProperty(property: ABPropertyID, of person: ABRecord, toEqual expected: String) {
    let actual = ABRecordCopyValue(person, property).takeRetainedValue() as String
    XCTAssertEqual(expected, actual)
  }
}
