import XCTest

class CoreExtensionTests: XCTestCase {
  func testDictionaryHasKey() {
    let dict = ["foo": 1]
    XCTAssertTrue(dict.hasKey("foo"))
    XCTAssertFalse(dict.hasKey("bar"))
  }

  func testCollectionTypeCountWhere() {
    XCTAssertEqual(["a", "b", ].countWhere { $0 == "c" }, 0)
    XCTAssertEqual(["A", "b", "C"].countWhere { $0 == $0.uppercaseString }, 2)
    XCTAssertEqual(["a": 1, "b": 2, "c": 3].countWhere { $1 % 2 == 0 }, 1)
  }

  func testCollectionTypeFindElementWhere() {
    XCTAssertNil([1, 2].findElementWhere { $0 % 3 == 0 })

    XCTAssertEqual([1, 2, 3, 4].findElementWhere { $0 % 2 == 0 }, 2)

    let pair = ["a": 1, "b": 2, "c": 5].findElementWhere { $1 % 2 == 0 }
    XCTAssert(pair != nil)
    XCTAssertEqual(pair!.0, "b")
    XCTAssertEqual(pair!.1, 2)
  }

  func testCollectionTypeFindIndexWhere() {
    XCTAssertNil(["a", "b"].findIndexWhere { $0 == "d" })
    XCTAssertEqual(["a", "b", "b"].findIndexWhere { $0 == "b" }, 1)
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
    XCTAssertFalse(NSURL(string: "h")!.isValidHTTPURL)
    XCTAssertFalse(NSURL(string: "")!.isValidHTTPURL)
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
