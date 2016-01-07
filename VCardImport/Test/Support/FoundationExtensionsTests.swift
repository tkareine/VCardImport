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

  func testDateAtMidnight() {
    let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
    calendar.timeZone = NSTimeZone(forSecondsFromGMT: 0)

    let comp = NSDateComponents()
    comp.year = 2016
    comp.month = 2
    comp.day = 29
    comp.hour = 13
    comp.minute = 23
    comp.second = 34

    let date = calendar.dateFromComponents(comp)!

    XCTAssertEqual(date.dateAtMidnight(calendar).ISOString, "2016-02-29T00:00:00Z")
  }

  func testDateIsBefore() {
    let before = NSDate(timeIntervalSinceReferenceDate: 1)
    let after = NSDate(timeIntervalSinceReferenceDate: 2)
    XCTAssertTrue(before.isBefore(after))
    XCTAssertFalse(after.isBefore(before))
    XCTAssertFalse(before.isBefore(before))
  }

  func testDateDescribeRelativeDateToHuman() {
    let secondsInDay: NSTimeInterval = 24 * 60 * 60
    let secondsIn10minutes: NSTimeInterval = 10 * 60

    let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
    calendar.timeZone = NSTimeZone(forSecondsFromGMT: 0)

    let comp = calendar.components([.Year, .Month, .Day], fromDate: NSDate())
    comp.hour = 14
    comp.minute = 56

    let todayAfternoon = calendar.dateFromComponents(comp)!
    let yesterdayAfternoon = todayAfternoon.dateByAddingTimeInterval(-secondsInDay + secondsIn10minutes)
    let theDayAfterAtAfternoon = yesterdayAfternoon.dateByAddingTimeInterval(-secondsInDay - secondsIn10minutes)

    XCTAssertEqual(todayAfternoon.describeRelativeDateToHuman(calendar), "today \(todayAfternoon.localeShortTimeString)")
    XCTAssertEqual(yesterdayAfternoon.describeRelativeDateToHuman(calendar), "yesterday \(yesterdayAfternoon.localeShortTimeString)")
    XCTAssertEqual(theDayAfterAtAfternoon.describeRelativeDateToHuman(calendar), theDayAfterAtAfternoon.localeMediumDateTimeString)
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
