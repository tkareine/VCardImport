import Foundation

class URLDownloadFactory {
  private let makeHTTPSession: () -> HTTPRequestable

  init(httpSessionsWith makeHTTPSession: () -> HTTPRequestable) {
    self.makeHTTPSession = makeHTTPSession
  }

  func makeDownloader(
    connection connection: VCardSource.Connection,
    headers: HTTPRequest.Headers)
    -> URLDownloadable
  {
    switch connection.authenticationMethod {
    case .None:
      return StandardURLDownloader(
        httpRequestsWith: makeHTTPSession(),
        url: connection.vcardURLasURL(),
        headers: headers)
    case .BasicAuth:
      return StandardURLDownloader(
        httpRequestsWith: makeHTTPSession(),
        url: connection.vcardURLasURL(),
        headers: headers,
        credential: NSURLCredential(
          user: connection.username ?? "",
          password: connection.password ?? "",
          persistence: .ForSession))
    case .PostForm:
      return PostFormURLDownloader(
        httpRequestsWith: makeHTTPSession(),
        vcardURL: connection.vcardURLasURL(),
        loginURL: connection.loginURLasURL()!,
        username: connection.username ?? "",
        password: connection.password ?? "",
        headers: headers)
    }
  }
}
