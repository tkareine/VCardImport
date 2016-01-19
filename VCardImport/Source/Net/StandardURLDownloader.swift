import Foundation
import MiniFuture

class StandardURLDownloader: URLDownloadable {
  private let httpRequests: HTTPRequestable
  private let url: NSURL
  private let headers: HTTPRequest.Headers
  private let credential: NSURLCredential?

  init(
    httpRequestsWith httpRequests: HTTPRequestable,
    url: NSURL,
    headers: HTTPRequest.Headers,
    credential: NSURLCredential? = nil)
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
    onProgress: HTTPRequest.OnDownloadProgressCallback? = nil)
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
