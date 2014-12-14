import XCTest

class CoreExtensionTests: XCTestCase {
  func testArrayAny() {
    XCTAssertTrue(["a", "B", "c"].any { $0 == $0.uppercaseString })
    XCTAssertFalse(["a", "b", "c"].any { $0 == $0.uppercaseString })
  }

  func testArrayFind() {
    XCTAssert(["a", "B", "c"].find { $0 == $0.uppercaseString } == "B")
    XCTAssert(["a", "b", "c"].find { $0 == $0.uppercaseString } == nil)
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
