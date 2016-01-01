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
    case .BasicAuth:
      return BasicAuthURLDownloader(
        httpRequestsWith: makeHTTPSession(),
        url: connection.vcardURLasURL(),
        headers: headers,
        credential: makeCredential(
          username: connection.username,
          password: connection.password,
          persistence: .ForSession))
    case .PostForm:
      return PostFormURLDownloader(
        httpRequestsWith: makeHTTPSession(),
        vcardURL: connection.vcardURLasURL(),
        loginURL: connection.loginURLasURL()!,
        username: connection.username,
        password: connection.password,
        headers: headers)
    }
  }

  // MARK: Helpers

  private func makeCredential(
    username username: String,
    password: String,
    persistence: NSURLCredentialPersistence = .None)
    -> NSURLCredential?
  {
    if !username.isEmpty {
      return NSURLCredential(user: username, password: password, persistence: persistence)
    } else {
      return nil
    }
  }
}
