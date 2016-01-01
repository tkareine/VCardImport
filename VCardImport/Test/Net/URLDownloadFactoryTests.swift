import MiniFuture
import XCTest

class URLDownloadFactoryTests: XCTestCase {
  func testBasicAuthMethodSendsCredentials() {
    let headRequestedExpectation = expectationWithDescription("HEAD requested")

    class TestHttpSession: FakeHTTPSession {
      private let onHeadCallback: NSURLCredential? -> Void

      init(headHandler onHeadCallback: NSURLCredential? -> Void) {
        self.onHeadCallback = onHeadCallback
      }

      override func head(
        url: NSURL,
        headers: HTTPRequest.Headers,
        credential: NSURLCredential?)
        -> Future<NSHTTPURLResponse>
      {
        onHeadCallback(credential)
        return super.head(url, headers: headers, credential: credential)
      }
    }

    let httpSession = TestHttpSession(headHandler: { creds in
      XCTAssertEqual(creds!.user, "uname")
      XCTAssertEqual(creds!.password, "passwd")
      XCTAssert(creds!.persistence == .ForSession)
      headRequestedExpectation.fulfill()
    })

    makeURLDownloadFactory(usingHTTPSession: httpSession)
      .makeDownloader(connection: makeConnection(.BasicAuth), headers: [:])
      .requestFileHeaders()

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testPostFormMethodTreatsAuthenticationAsFailureIfVCardURLResponseHasSameRequestURLPathAsForLoginURLResponse() {
    let httpSession = FakeHTTPSession()
    let connection = makeConnection(.PostForm)

    httpSession.fakeRespondTo(
      connection.loginURLasURL()!,
      withResponse: makeHTTPResponse(NSURL(string: "https://example.com/login-redir?attempts=1")!))

    httpSession.fakeRespondTo(
      connection.vcardURLasURL(),
      withResponse: makeHTTPResponse(NSURL(string: "https://example.com/login-redir?attempts=2")!))

    let result = makeURLDownloadFactory(usingHTTPSession: httpSession)
      .makeDownloader(connection: connection, headers: [:])
      .requestFileHeaders()
      .get()

    XCTAssertTrue(result.isFailure)

    do {
      try result.value()
      XCTFail()
    } catch {
      XCTAssertEqual((error as NSError).localizedDescription, "Invalid login")
    }
  }

  func testPostFormMethodTreatsAuthenticationAsSuccessIfVCardURLResponseHasDifferentURLPathFromLoginURLResponse() {
    let httpSession = FakeHTTPSession()
    let connection = makeConnection(.PostForm)

    httpSession.fakeRespondTo(
      connection.loginURLasURL()!,
      withResponse: makeHTTPResponse(NSURL(string: "https://example.com/")!))

    httpSession.fakeRespondTo(
      connection.vcardURLasURL(),
      withResponse: makeHTTPResponse(NSURL(string: "https://example.com/vcards")!))

    let result = makeURLDownloadFactory(usingHTTPSession: httpSession)
      .makeDownloader(connection: connection, headers: [:])
      .requestFileHeaders()
      .get()

    XCTAssertTrue(result.isSuccess)
  }

  private func makeConnection(authenticationMethod: HTTPRequest.AuthenticationMethod)
    -> VCardSource.Connection
  {
    return VCardSource.Connection(
      vcardURL: "https://example.com/vcards",
      authenticationMethod: authenticationMethod,
      username: "uname",
      password: "passwd",
      loginURL: authenticationMethod == .PostForm ? "https://example.com/login" : nil)
  }

  private func makeURLDownloadFactory(
    usingHTTPSession httpSession: HTTPRequestable)
    -> URLDownloadFactory
  {
    return URLDownloadFactory(httpSessionsWith: { httpSession })
  }

  private func makeHTTPResponse(url: NSURL) -> NSHTTPURLResponse {
    return NSHTTPURLResponse(
      URL: url,
      statusCode: 200,
      HTTPVersion: "HTTP/1.1",
      headerFields: [:])!
  }
}
