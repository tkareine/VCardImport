import XCTest

class RecordNameTests: XCTestCase {
  let leonKennedy0 = RecordName.of(TestRecords.makePerson(firstName: "Leon", lastName: "Kennedy"))!
  let leonKennedy1 = RecordName.of(TestRecords.makePerson(firstName: "Leon", lastName: "Kennedy"))!
  let leonKennedyS0 = RecordName.of(TestRecords.makePerson(firstName: "Leon", lastName: "Kennedy", nickName: "S"))!
  let leonKennedyS1 = RecordName.of(TestRecords.makePerson(firstName: "Leon", lastName: "Kennedy", nickName: "S"))!
  let jillValentine = RecordName.of(TestRecords.makePerson(firstName: "Jill", lastName: "Valentine"))!
  let s0 = RecordName.of(TestRecords.makePerson(nickName: "S"))!
  let s1 = RecordName.of(TestRecords.makePerson(nickName: "S"))!
  let umbrella0 = RecordName.of(TestRecords.makeOrganization(name: "Umbrella"))!
  let umbrella1 = RecordName.of(TestRecords.makeOrganization(name: "Umbrella"))!
  let umbrellaPF = RecordName.of(TestRecords.makePerson(firstName: "Umbrella"))!
  let umbrellaPL = RecordName.of(TestRecords.makePerson(lastName: "Umbrella"))!
  let umbrellaPN = RecordName.of(TestRecords.makePerson(nickName: "Umbrella"))!
  let rpd = RecordName.of(TestRecords.makeOrganization(name: "RPD"))!

  func testEqualityAndHashValueForPersonsWithSameFirstAndLastNames() {
    XCTAssert(leonKennedy0 == leonKennedy0)
    XCTAssert(leonKennedy0 == leonKennedy1)
    XCTAssertEqual(leonKennedy0.hashValue, leonKennedy1.hashValue)
  }

  func testEqualityAndHashValueForPersonsWithSameFirstAndLastAndNickNames() {
    XCTAssert(leonKennedyS0 == leonKennedyS0)
    XCTAssert(leonKennedyS0 == leonKennedyS1)
    XCTAssertEqual(leonKennedyS0.hashValue, leonKennedyS1.hashValue)
  }

  func testEqualityAndHashValueForPersonsWithSameNickNames() {
    XCTAssert(s0 == s0)
    XCTAssert(s0 == s1)
    XCTAssertEqual(s0.hashValue, s1.hashValue)
  }

  func testEqualityAndHashValueForPersonsWithDifferentNames() {
    XCTAssert(leonKennedy0 != jillValentine)
    XCTAssertNotEqual(leonKennedy0.hashValue, jillValentine.hashValue)

    XCTAssert(leonKennedy0 != leonKennedyS0)
    XCTAssertNotEqual(leonKennedy0.hashValue, leonKennedyS0.hashValue)

    XCTAssert(leonKennedyS0 != s0)
    XCTAssertNotEqual(leonKennedyS0.hashValue, s0.hashValue)
  }

  func testEqualityAndHashValueForOrganizationsWithSameName() {
    XCTAssert(umbrella0 == umbrella0)
    XCTAssert(umbrella0 == umbrella1)
    XCTAssertEqual(umbrella0.hashValue, umbrella1.hashValue)
  }

  func testEqualityAndHashValueForOrganizationsWithDifferentName() {
    XCTAssert(umbrella0 != rpd)
    XCTAssertNotEqual(umbrella0.hashValue, rpd.hashValue)
  }

  func testEqualityAndHashValueForPersonAndOrganization() {
    XCTAssert(leonKennedy0 != umbrella0)
    XCTAssertNotEqual(leonKennedy0.hashValue, umbrella0.hashValue)

    XCTAssert(leonKennedy0 != rpd)
    XCTAssertNotEqual(leonKennedy0.hashValue, rpd.hashValue)

    XCTAssert(umbrella0 != umbrellaPF)
    XCTAssertNotEqual(umbrella0.hashValue, umbrellaPF.hashValue)

    XCTAssert(umbrella0 != umbrellaPL)
    XCTAssertNotEqual(umbrella0.hashValue, umbrellaPL.hashValue)

    XCTAssert(umbrella0 != umbrellaPN)
    XCTAssertNotEqual(umbrella0.hashValue, umbrellaPN.hashValue)
  }

  func testEmptyNameForPersonReturnsNil() {
    XCTAssertNil(RecordName.of(TestRecords.makePerson()))
    XCTAssertNil(RecordName.of(TestRecords.makePerson(firstName: "")))
    XCTAssertNil(RecordName.of(TestRecords.makePerson(lastName: "")))
    XCTAssertNil(RecordName.of(TestRecords.makePerson(nickName: "")))
    XCTAssertNil(RecordName.of(TestRecords.makePerson(firstName: "", lastName: "")))
    XCTAssertNil(RecordName.of(TestRecords.makePerson(firstName: "", lastName: "", nickName: "")))
    XCTAssertNotNil(RecordName.of(TestRecords.makePerson(firstName: "Jill")))
    XCTAssertNotNil(RecordName.of(TestRecords.makePerson(lastName: "Valentine")))
    XCTAssertNotNil(RecordName.of(TestRecords.makePerson(nickName: "JV")))
  }

  func testEmptyNameForOrganizationReturnsNil() {
    XCTAssertNil(RecordName.of(TestRecords.makeOrganization()))
    XCTAssertNil(RecordName.of(TestRecords.makeOrganization(name: "")))
  }

  func testTreatsEmptyNickNameAsSameWithoutNickName() {
    let lk = RecordName.of(TestRecords.makePerson(firstName: "Leon", lastName: "Kennedy", nickName: ""))!

    XCTAssert(leonKennedy0 == lk)
    XCTAssert(leonKennedy0 == lk)
    XCTAssertEqual(leonKennedy0.hashValue, lk.hashValue)
  }
}
