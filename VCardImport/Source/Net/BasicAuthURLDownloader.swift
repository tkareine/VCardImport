import Foundation
import MiniFuture

class BasicAuthURLDownloader: URLDownloadable {
  private let httpRequests: HTTPRequestable
  private let url: NSURL
  private let headers: HTTPRequest.Headers
  private let credential: NSURLCredential?

  init(
    httpRequestsWith httpRequests: HTTPRequestable,
    url: NSURL,
    headers: HTTPRequest.Headers,
    credential: NSURLCredential?)
  {
    self.httpRequests = httpRequests
    self.url = url
    self.headers = headers
    self.credential = credential
  }

  func requestFileHeaders() -> Future<NSHTTPURLResponse> {
    return httpRequests.head(url, headers: headers, credential: credential)
  }

  func downloadFile(
    to fileURL: NSURL,
    onProgress: HTTPRequest.OnProgressCallback? = nil)
    -> Future<NSURL>
  {
    return httpRequests.download(
      url,
      to: fileURL,
      headers: headers,
      credential: credential,
      onProgress: onProgress)
  }
}
