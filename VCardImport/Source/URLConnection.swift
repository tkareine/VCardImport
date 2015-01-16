import Foundation

class URLConnection {
  typealias Headers = [String: String]

  private let SuccessStatusCodes = 200..<300

  private let session: NSURLSession

  init() {
    func makeHeaders() -> [String: String] {
      return [
        "Accept-Encoding": "gzip,compress;q=0.9",
        "User-Agent": Config.AppInfo
      ]
    }

    func makeConfig() -> NSURLSessionConfiguration {
      let config = NSURLSessionConfiguration.ephemeralSessionConfiguration()
      config.allowsCellularAccess = true
      config.timeoutIntervalForRequest = 60
      config.timeoutIntervalForResource = 60 * 60 * 10
      config.HTTPAdditionalHeaders = makeHeaders()
      return config
    }

    func makeOperationQueue() -> NSOperationQueue {
      let operationQueue = NSOperationQueue()
      operationQueue.qualityOfService = .UserInitiated
      operationQueue.maxConcurrentOperationCount = 6
      return operationQueue
    }

    session = NSURLSession(
      configuration: makeConfig(),
      delegate: nil,
      delegateQueue: makeOperationQueue())
  }

  func download(url: NSURL, to destination: NSURL, headers: Headers = [:]) -> Future<NSURL> {
    let promise = Future<NSURL>.promise()
    let request = makeURLRequest(url: url, headers: headers)
    let task = session.downloadTaskWithRequest(request, completionHandler: { location, response, error in
      if let err = error {
        promise.reject("\(err.localizedFailureReason): \(err.localizedDescription)")
      } else if let res = response as? NSHTTPURLResponse {
        if self.isSuccessStatusCode(res.statusCode) {
          Files.move(from: location, to: destination)
          promise.resolve(destination)
        } else {
          let statusDesc = NSHTTPURLResponse.localizedStringForStatusCode(res.statusCode)
          promise.reject("(\(res.statusCode)) \(statusDesc)")
        }
      } else {
        promise.reject("Unknown download error")
      }
    })
    task.resume()
    return promise
  }

  private func makeURLRequest(#url: NSURL, headers: Headers) -> NSURLRequest {
    let request = NSMutableURLRequest(URL: url)
    for (headerName, headerValue) in headers {
      request.setValue(headerValue, forHTTPHeaderField: headerName)
    }
    return request
  }

  private func isSuccessStatusCode(code: Int) -> Bool {
    return contains(SuccessStatusCodes, code)
  }
}
