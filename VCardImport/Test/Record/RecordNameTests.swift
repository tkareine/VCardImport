import AddressBook
import XCTest

class RecordNameTests: XCTestCase {
  func testEqualityAndHashValue() {
    let leon0 = RecordName.of(makePersonRecord(firstName: "Leon", lastName: "Kennedy"))!
    let leon1 = RecordName.of(makePersonRecord(firstName: "Leon", lastName: "Kennedy"))!
    let jill = RecordName.of(makePersonRecord(firstName: "Jill", lastName: "Valentine"))!
    let umbrella0 = RecordName.of(makeOrganizationRecord(name: "Umbrella"))!
    let umbrella1 = RecordName.of(makeOrganizationRecord(name: "Umbrella"))!
    let umbrellaP = RecordName.of(makePersonRecord(firstName: "Umbrella", lastName: ""))!
    let rpd = RecordName.of(makeOrganizationRecord(name: "RPD"))!

    XCTAssert(leon0 == leon0)
    XCTAssert(leon0 == leon1)
    XCTAssertEqual(leon0.hashValue, leon1.hashValue)

    XCTAssert(leon0 != jill)
    XCTAssertNotEqual(leon0.hashValue, jill.hashValue)

    XCTAssert(umbrella0 == umbrella0)
    XCTAssert(umbrella0 == umbrella1)
    XCTAssertEqual(umbrella0.hashValue, umbrella1.hashValue)

    XCTAssert(umbrella0 != umbrellaP)
    XCTAssertNotEqual(umbrella0.hashValue, umbrellaP.hashValue)

    XCTAssert(umbrella0 != rpd)
    XCTAssertNotEqual(umbrella0.hashValue, rpd.hashValue)

    XCTAssert(leon0 != umbrella0)
    XCTAssert(leon0 != umbrellaP)
    XCTAssert(leon0 != rpd)
  }

  func testEmptyNameReturnsNil() {
    XCTAssertNil(RecordName.of(makePersonRecord(firstName: "", lastName: "")))
    XCTAssertNotNil(RecordName.of(makePersonRecord(firstName: "Jill", lastName: "")))
    XCTAssertNotNil(RecordName.of(makePersonRecord(firstName: "", lastName: "Valentine")))

    XCTAssertNil(RecordName.of(makeOrganizationRecord(name: "")))
  }

  private func makePersonRecord(#firstName: NSString, lastName: NSString) -> ABRecord {
    let record: ABRecord = ABPersonCreate().takeRetainedValue()
    Records.setValue(firstName, toSingleValueProperty: kABPersonFirstNameProperty, of: record)
    Records.setValue(lastName, toSingleValueProperty: kABPersonLastNameProperty, of: record)
    return record
  }

  private func makeOrganizationRecord(#name: NSString) -> ABRecord {
    let record: ABRecord = ABPersonCreate().takeRetainedValue()
    Records.setValue(kABPersonKindOrganization, toSingleValueProperty: kABPersonKindProperty, of: record)
    Records.setValue(name, toSingleValueProperty: kABPersonOrganizationProperty, of: record)
    return record
  }
}
