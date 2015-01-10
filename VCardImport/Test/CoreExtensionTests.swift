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

  func testArrayPartition() {
    let (first, second) = ["a", "B", "c"].partition { $0 == $0.uppercaseString }
    XCTAssertEqual(first, ["B"])
    XCTAssertEqual(second, ["a", "c"])
  }

  func testDictionaryFirst() {
    let empty: [String: Int] = [:]
    XCTAssert(empty.first == nil)
    XCTAssert(["a": 1].first! == ("a", 1))
  }

  func testDictionaryHasKey() {
    let dict = ["foo": 1]
    XCTAssertTrue(dict.hasKey("foo"))
    XCTAssertFalse(dict.hasKey("bar"))
  }

  func testDateISOString() {
    var date = NSDate(timeIntervalSinceReferenceDate: 0)
    XCTAssertEqual(date.ISOString, "2001-01-01T00:00:00Z")
  }

  func testDateFromISOString() {
    var date = NSDate.dateFromISOString("2001-01-01T00:00:00Z")!
    XCTAssertEqual(date, NSDate(timeIntervalSinceReferenceDate: 0))
  }

  func testDateFromAndToISOString() {
    let isoString = "2014-12-23T10:32:45Z"
    var date = NSDate.dateFromISOString(isoString)!
    XCTAssertEqual(date.ISOString as String, isoString)
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

  func testCountWhere() {
    XCTAssertEqual(countWhere(["A", "b", "C"], { $0 == $0.uppercaseString }), 2)
    XCTAssertEqual(countWhere(["a": 1, "b": 2, "c": 3], { (k, v) in v % 2 == 0 }), 1)
  }

  func testMapDictionary() {
    let dict: [String: String] = mapDictionary(["a", "b"]) { idx, val in "\(idx)\(val)" }
    XCTAssertEqual(dict, ["0a": "a", "1b": "b"])
  }
}
