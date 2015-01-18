import Foundation

class URLConnection {
  typealias Headers = [String: String]

  private let SuccessStatusCodes = 200..<300

  private let session: NSURLSession

  init() {
    func makeHeaders() -> [String: String] {
      return [
        "Accept-Encoding": "gzip,compress;q=0.9",
        "User-Agent": "\(Config.Executable)/\(Config.BundleIdentifier) (\(Config.Version); OS \(Config.OS))"
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

  func request(method: Method, url: NSURL, headers: Headers = [:]) -> Future<NSHTTPURLResponse> {
    let request = makeURLRequest(url: url, method: method, headers: headers)
    return promisifyTask { promise in
      return self.session.dataTaskWithRequest(request) { data, response, error in
        if error != nil {
          promise.reject(Config.Net.GenericErrorDescription)
        } else if let res = response as? NSHTTPURLResponse {
          if self.isSuccessStatusCode(res.statusCode) {
            promise.resolve(res)
          } else {
            promise.reject(res)
          }
        } else {
          promise.reject("Unknown request error for \(method) \(url)")
        }
      }
    }
  }

  func head(url: NSURL, headers: Headers = [:]) -> Future<NSHTTPURLResponse> {
    return request(.Head, url: url, headers: headers)
  }

  func download(url: NSURL, to destination: NSURL, headers: Headers = [:]) -> Future<NSURL> {
    let request = makeURLRequest(url: url, headers: headers)
    return promisifyTask { promise in
      return self.session.downloadTaskWithRequest(request) { location, response, error in
        if error != nil {
          promise.reject(Config.Net.GenericErrorDescription)
        } else if let res = response as? NSHTTPURLResponse {
          if self.isSuccessStatusCode(res.statusCode) {
            Files.move(from: location, to: destination)
            promise.resolve(destination)
          } else {
            promise.reject(res)
          }
        } else {
          promise.reject("Unknown download error for \(url)")
        }
      }
    }
  }

  private func makeURLRequest(#url: NSURL, method: Method = .Get, headers: Headers = [:]) -> NSURLRequest {
    let request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = method.description
    for (headerName, headerValue) in headers {
      request.setValue(headerValue, forHTTPHeaderField: headerName)
    }
    return request
  }

  private func promisifyTask<T>(
    block: PromiseFuture<T> -> NSURLSessionTask)
    -> Future<T>
  {
    let promise = Future<T>.promise()
    let task = block(promise)
    task.resume()
    return promise
  }

  private func isSuccessStatusCode(code: Int) -> Bool {
    return contains(SuccessStatusCodes, code)
  }

  enum Method: Printable {
    case Head
    case Get

    var description: String {
      switch self {
      case Head:
        return "HEAD"
      case Get:
        return "GET"
      }
    }
  }
}
