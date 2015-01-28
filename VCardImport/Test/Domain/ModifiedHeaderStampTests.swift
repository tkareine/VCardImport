import XCTest

class ModifiedHeaderStampTests: XCTestCase {
  func testPrefersLastModifiedHeaderFirst() {
    let mhs = ModifiedHeaderStamp(headers: ["Last-Modified": "lm", "ETag": "et"])!
    XCTAssertEqual(mhs.name, "Last-Modified")
    XCTAssertEqual(mhs.value, "lm")
  }

  func testPrefersETagHeaderSecond() {
    let mhs = ModifiedHeaderStamp(headers: ["ETag": "et"])!
    XCTAssertEqual(mhs.name, "ETag")
    XCTAssertEqual(mhs.value, "et")
  }

  func testTrimsHeaderValue() {
    let mhs = ModifiedHeaderStamp(headers: ["Last-Modified": "  lm \t\n"])!
    XCTAssertEqual(mhs.name, "Last-Modified")
    XCTAssertEqual(mhs.value, "lm")
  }

  func testEquatable() {
    let mhs0 = ModifiedHeaderStamp(name: "Last-Modified", value: "lm")
    let mhs1 = ModifiedHeaderStamp(name: "Last-Modified", value: "lm")
    let mhs2 = ModifiedHeaderStamp(name: "Last-Modified", value: "lm2")
    XCTAssertEqual(mhs0, mhs1)
    XCTAssertNotEqual(mhs0, mhs2)
  }

  func testDetectsChangedHeader() {
    let mhs0 = ModifiedHeaderStamp(headers: ["ETag": "et"])!
    let mhs1 = ModifiedHeaderStamp(headers: ["Last-Modified": "lm", "ETag": "et"])!
    let mhs2 = ModifiedHeaderStamp(headers: ["Last-Modified": "lm"])!
    XCTAssertNotEqual(mhs0, mhs1)
    XCTAssertEqual(mhs1, mhs2)
  }
}
