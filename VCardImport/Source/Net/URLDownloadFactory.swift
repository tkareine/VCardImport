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
    case .HTTPAuth:
      return HTTPAuthURLDownloader(
        httpRequestsWith: makeHTTPSession(),
        url: connection.toURL(),
        headers: headers,
        credential: makeCredential(
          username: connection.username,
          password: connection.password,
          persistence: .ForSession))
    case .PostForm:
      return PostFormURLDownloader(
        httpRequestsWith: makeHTTPSession(),
        baseURL: connection.toURL(),
        loginURLPath: "/login",
        vcardURLPath:  "/vcards",
        headers: headers,
        username: connection.username,
        password: connection.password)
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
