import Foundation
import Alamofire

struct URLConnection {
  static func download(url: NSURL, toDestination destinationURL: NSURL) -> Future<NSURL> {
    let promise = Future<NSURL>.promise()
    Alamofire
      .download(.GET, url) { _, _ in destinationURL }
      .response(
        queue: QueueExecution.backgroundQueue,
        serializer: Alamofire.Request.responseDataSerializer(),
        completionHandler: { request, response, _, error in
          if let err = error {
            promise.reject("\(err.localizedFailureReason): \(err.localizedDescription)")
          } else if let res = response {
            if res.statusCode == 200 {
              promise.resolve(destinationURL)
            } else {
              let statusDesc = NSHTTPURLResponse.localizedStringForStatusCode(res.statusCode)
              promise.reject("(\(res.statusCode)) \(statusDesc)")
            }
          } else {
            promise.reject("Unknown download error")
          }
        }
      )
    return promise
  }
}