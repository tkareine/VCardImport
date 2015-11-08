import Foundation
import MiniFuture

class PostFormURLDownloader: URLDownloadable {
  private let httpRequests: HTTPRequestable
  private let loginURL: NSURL
  private let vcardURL: NSURL
  private let headers: HTTPRequest.Headers
  private let username: String
  private let password: String

  init(
    httpRequestsWith httpRequests: HTTPRequestable,
    baseURL: NSURL,
    loginURLPath: String,
    vcardURLPath: String,
    headers: HTTPRequest.Headers,
    username: String,
    password: String)
  {
    self.httpRequests = httpRequests
    self.loginURL = NSURL(string: loginURLPath, relativeToURL: baseURL)!.absoluteURL
    self.vcardURL = NSURL(string: vcardURLPath, relativeToURL: baseURL)!.absoluteURL
    self.headers = headers
    self.username = username
    self.password = password
  }

  func requestFileHeaders() -> Future<NSHTTPURLResponse> {
    return httpRequests
      .post(
        loginURL,
        headers: [:],
        parameters: ["username": username, "password": password])
      .flatMap { [unowned self] response in
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
