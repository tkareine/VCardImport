import Foundation
import Alamofire

struct URLConnection {
  static func download(url: NSURL, toDestination destinationURL: NSURL) -> Future<NSURL> {
    let promise = Future<NSURL>.promise()
    Alamofire
      .download(.GET, url) { tmpURL, response in
        NSLog("downloading: %@\n%@", tmpURL, response)
        return destinationURL
      }
      .progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
        NSLog("progress: %d/%d", totalBytesRead, totalBytesExpectedToRead)
      }
      .response(
        queue: BackgroundExecution.sharedQueue,
        serializer: Alamofire.Request.responseDataSerializer(),
        completionHandler: { request, response, _, error in
          NSLog("got response: %@", response!)
          if let err = error {
            NSLog("download failed: %@", err)
            if !promise.isCompleted {
              promise.reject("\(err.localizedFailureReason): \(err.localizedDescription)")
            }
          } else {
            promise.resolve(destinationURL)
          }
        }
      )
    return promise
  }
}