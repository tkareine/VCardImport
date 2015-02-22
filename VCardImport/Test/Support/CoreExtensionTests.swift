import XCTest

class CoreExtensionTests: XCTestCase {
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

  func testStringCapitalized() {
    XCTAssertEqual("a".capitalized, "A")
    XCTAssertEqual("foo bar".capitalized, "Foo bar")
    XCTAssertEqual("".capitalized, "")
  }

  func testStringTrimmed() {
    XCTAssertEqual("a \n \tb".trimmed, "a \n \tb")
    XCTAssertEqual(" \n ab \t".trimmed, "ab")
    XCTAssertEqual(" \n \t".trimmed, "")
    XCTAssertEqual("".trimmed, "")
  }

  func testDateISOString() {
    let date = NSDate(timeIntervalSinceReferenceDate: 0)
    XCTAssertEqual(date.ISOString, "2001-01-01T00:00:00Z")
  }

  func testDateFromISOString() {
    let date = NSDate.dateFromISOString("2001-01-01T00:00:00Z")!
    XCTAssertEqual(date, NSDate(timeIntervalSinceReferenceDate: 0))
  }

  func testDateFromAndToISOString() {
    let isoString = "2014-12-23T10:32:45Z"
    let date = NSDate.dateFromISOString(isoString)!
    XCTAssertEqual(date.ISOString as String, isoString)
  }

  func testURLHTTPURLValidation() {
    XCTAssertTrue(NSURL(string: "http://192.168.0.1/")!.isValidHTTPURL)
    XCTAssertTrue(NSURL(string: "http://0.0.0.0/")!.isValidHTTPURL)
    XCTAssertTrue(NSURL(string: "http://localhost/")!.isValidHTTPURL)
    XCTAssertTrue(NSURL(string: "http://localhost:8080/")!.isValidHTTPURL)
    XCTAssertTrue(NSURL(string: "http://www.example.com/foo/?bar=baz&ans=42&quux")!.isValidHTTPURL)
    XCTAssertTrue(NSURL(string: "http://example.com/?q=Test%20URL-encoded%20query")!.isValidHTTPURL)
    XCTAssertTrue(NSURL(string: "https://example.com/ev/#&test=true")!.isValidHTTPURL)
    XCTAssertTrue(NSURL(string: "https://EXAMPLE.com/EV/#&TEST=TRue")!.isValidHTTPURL)

    XCTAssertFalse(NSURL(string: "ftp://www.example.com/")!.isValidHTTPURL)
    XCTAssertFalse(NSURL(string: "http://")!.isValidHTTPURL)
    XCTAssertFalse(NSURL(string: "http://#")!.isValidHTTPURL)
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

  func testFindElement() {
    XCTAssert(findElement([1, 2, 3, 4], { $0 % 2 == 0}) == 2)

    let pair = findElement(["a": 1, "b": 2, "c": 5]) { (k, v) in v % 2 == 0 }
    XCTAssert(pair != nil)
    XCTAssertEqual(pair!.0, "b")
    XCTAssertEqual(pair!.1, 2)
  }

  func testFindIndex() {
    let index = findIndex(["a", "b", "b"]) { $0 == "b" }
    XCTAssert(index != nil)
    XCTAssertEqual(index!, 1)
  }
}
