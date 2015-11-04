import XCTest

class HTTPRequestTests: XCTestCase {
  func testURLRequestIncludesUserAgentHeader() {
    let req = HTTPRequest.makeURLRequest(url: NSURL(string: "http://example.com/")!)
    let ua = req.valueForHTTPHeaderField("User-Agent")!
    XCTAssertTrue(ua.hasPrefix("vCardTurbo/org.tkareine.vCard-Turbo "))
  }
}
