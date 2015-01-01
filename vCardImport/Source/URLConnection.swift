import Foundation
import Alamofire

struct URLConnection {
  static func download(url: NSURL, toDestination destinationURL: NSURL) -> Future<NSURL> {
    let promise = Future<NSURL>.promise()
    Alamofire
      .download(.GET, url) { _, _ in destinationURL }
      .progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
        NSLog("download progress %@: %d/%d", url, totalBytesRead, totalBytesExpectedToRead)
      }
      .response(
        queue: BackgroundExecution.sharedQueue,
        serializer: Alamofire.Request.responseDataSerializer(),
        completionHandler: { request, response, _, error in
          NSLog("download complete %@: %d", url, response!.statusCode)
          if let err = error {
            promise.reject("\(err.localizedFailureReason): \(err.localizedDescription)")
          } else if response != nil {
            promise.resolve(destinationURL)
          } else {
            promise.reject("unknown download error")
          }
        }
      )
    return promise
  }
}