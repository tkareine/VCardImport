import Foundation
import MiniFuture

protocol HTTPRequestable {
  func head(
    url: NSURL,
    headers: HTTPRequest.Headers,
    credential: NSURLCredential?)
    -> Future<NSHTTPURLResponse>

  func post(
    url: NSURL,
    headers: HTTPRequest.Headers,
    parameters: HTTPRequest.Parameters)
    -> Future<NSHTTPURLResponse>

  func download(
    url: NSURL,
    to destination: NSURL,
    headers: HTTPRequest.Headers,
    credential: NSURLCredential?,
    onProgress: HTTPRequest.OnProgressCallback?)
    -> Future<NSURL>
}
