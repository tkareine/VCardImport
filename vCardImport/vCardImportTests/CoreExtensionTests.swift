import XCTest

class CoreExtensionTests: XCTestCase {
  func testArrayAny() {
    XCTAssertTrue(["a", "B", "c"].any { $0 == $0.uppercaseString })
    XCTAssertFalse(["a", "b", "c"].any { $0 == $0.uppercaseString })
  }

  func testArrayCountWhere() {
    XCTAssert(["A", "b", "C"].countWhere { $0 == $0.uppercaseString } == 2)
    XCTAssert(["a", "b", "c"].countWhere { $0 == $0.uppercaseString } == 0)
  }

  func testArrayFind() {
    XCTAssert(["a", "B", "c"].find { $0 == $0.uppercaseString } == "B")
    XCTAssert(["a", "b", "c"].find { $0 == $0.uppercaseString } == nil)
  }

  func testArrayPartition() {
    let (first, second) = ["a", "B", "c"].partition { $0 == $0.uppercaseString }
    XCTAssertEqual(first, ["B"])
    XCTAssertEqual(second, ["a", "c"])
  }

  func test2TupleEquality() {
    XCTAssertTrue((0, "1") == (0, "1"))
    XCTAssertFalse((0, "1") == (0, "2"))
    XCTAssertFalse((0, "1") == (1, "1"))
    XCTAssertFalse(("0", "1") == (0, "1"))
  }

  func test2TupleNonEquality() {
    XCTAssertFalse((0, "1") != (0, "1"))
    XCTAssertTrue((0, "1") != (0, "2"))
    XCTAssertTrue((0, "1") != (1, "1"))
    XCTAssertTrue(("0", "1") != (0, "1"))
  }
}
