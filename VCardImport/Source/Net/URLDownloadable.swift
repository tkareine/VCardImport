import Foundation
import MiniFuture

protocol URLDownloadable {
  func requestFileHeaders() -> Future<NSHTTPURLResponse>

  func downloadFile(
    to fileURL: NSURL,
    onProgress: HTTPRequest.OnDownloadProgressCallback?)
    -> Future<NSURL>
}
