import AddressBook
import XCTest

class RecordNameTests: XCTestCase {
  func testEqualityAndHashValue() {
    let leon0 = RecordName.of(TestRecords.makePerson(firstName: "Leon", lastName: "Kennedy"))!
    let leon1 = RecordName.of(TestRecords.makePerson(firstName: "Leon", lastName: "Kennedy"))!
    let jill = RecordName.of(TestRecords.makePerson(firstName: "Jill", lastName: "Valentine"))!
    let umbrella0 = RecordName.of(TestRecords.makeOrganization(name: "Umbrella"))!
    let umbrella1 = RecordName.of(TestRecords.makeOrganization(name: "Umbrella"))!
    let umbrellaP = RecordName.of(TestRecords.makePerson(firstName: "Umbrella", lastName: ""))!
    let rpd = RecordName.of(TestRecords.makeOrganization(name: "RPD"))!

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
    XCTAssertNil(RecordName.of(TestRecords.makePerson(firstName: "", lastName: "")))
    XCTAssertNotNil(RecordName.of(TestRecords.makePerson(firstName: "Jill", lastName: "")))
    XCTAssertNotNil(RecordName.of(TestRecords.makePerson(firstName: "", lastName: "Valentine")))

    XCTAssertNil(RecordName.of(TestRecords.makeOrganization(name: "")))
  }
}
