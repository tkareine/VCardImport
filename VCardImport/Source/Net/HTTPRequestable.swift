import Foundation
import MiniFuture

protocol HTTPRequestable {
  func request(
    method: HTTPRequest.Method,
    url: NSURL,
    headers: HTTPRequest.Headers,
    credential: NSURLCredential?,
    onProgress: HTTPRequest.OnProgressCallback?)
    -> Future<NSHTTPURLResponse>

  func head(
    url: NSURL,
    headers: HTTPRequest.Headers,
    credential: NSURLCredential?)
    -> Future<NSHTTPURLResponse>

  func download(
    url: NSURL,
    to destination: NSURL,
    headers: HTTPRequest.Headers,
    credential: NSURLCredential?,
    onProgress: HTTPRequest.OnProgressCallback?)
    -> Future<NSURL>
}
