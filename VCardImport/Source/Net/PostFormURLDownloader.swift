import Foundation
import MiniFuture

class PostFormURLDownloader: URLDownloadable {
  private let httpRequests: HTTPRequestable
  private let vcardURL: NSURL
  private let loginURL: NSURL
  private let username: String
  private let password: String
  private let headers: HTTPRequest.Headers

  init(
    httpRequestsWith httpRequests: HTTPRequestable,
    vcardURL: NSURL,
    loginURL: NSURL,
    username: String,
    password: String,
    headers: HTTPRequest.Headers)
  {
    self.httpRequests = httpRequests
    self.vcardURL = vcardURL
    self.loginURL = loginURL
    self.username = username
    self.password = password
    self.headers = headers
  }

  func requestFileHeaders() -> Future<NSHTTPURLResponse> {
    return httpRequests
      .post(
        loginURL,
        headers: [:],
        parameters: ["username": username, "password": password])
      .flatMap { response in
        let loggedInOrLoginURL = response.URL!

        return self.httpRequests
          .head(self.vcardURL, headers: self.headers, credential: nil)
          .map { response in
            let fileURL = response.URL!

            guard fileURL.pathComponents! != loggedInOrLoginURL.pathComponents! else {
              // detected redirection back to login form
              throw Errors.urlRequestFailed("Invalid login")
            }

            return response
          }
      }
  }

  func downloadFile(
    to fileURL: NSURL,
    onProgress: HTTPRequest.OnProgressCallback?)
    -> Future<NSURL>
  {
    return httpRequests.download(
      vcardURL,
      to: fileURL,
      headers: headers,
      credential: nil,
      onProgress: onProgress)
  }
}
