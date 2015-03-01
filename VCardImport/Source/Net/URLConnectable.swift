import Foundation
import MiniFuture

protocol URLConnectable {
  func request(
    method: Request.Method,
    url: NSURL,
    headers: Request.Headers,
    credential: NSURLCredential?,
    onProgress: Request.OnProgressCallback?)
    -> Future<NSHTTPURLResponse>

  func head(
    url: NSURL,
    headers: Request.Headers,
    credential: NSURLCredential?)
    -> Future<NSHTTPURLResponse>

  func download(
    url: NSURL,
    to destination: NSURL,
    headers: Request.Headers,
    credential: NSURLCredential?,
    onProgress: Request.OnProgressCallback?)
    -> Future<NSURL>
}
