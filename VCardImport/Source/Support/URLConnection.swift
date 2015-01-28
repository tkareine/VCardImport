import Foundation
import Alamofire

class URLConnection {
  typealias Headers = [String: String]
  typealias ProgressBytes = (bytes: Int64, totalBytes: Int64, totalBytesExpected: Int64)
  typealias OnProgressCallback = ProgressBytes -> Void

  private let DefaultHeaders = [
    "User-Agent": "\(Config.Executable)/\(Config.BundleIdentifier) (\(Config.Version); OS \(Config.OS))"
  ]

  private let SuccessStatusCodes = 200..<300

  private let manager: Alamofire.Manager

  init() {
    func makeConfig() -> NSURLSessionConfiguration {
      let config = NSURLSessionConfiguration.ephemeralSessionConfiguration()
      config.allowsCellularAccess = true
      config.timeoutIntervalForRequest = 60
      config.timeoutIntervalForResource = 60 * 60 * 10
      return config
    }

    manager = Alamofire.Manager(configuration: makeConfig())
  }

  func request(
    method: Method,
    url: NSURL,
    headers: Headers = [:],
    credential: NSURLCredential? = nil,
    onProgress: OnProgressCallback? = nil)
    -> Future<NSHTTPURLResponse>
  {
    var request = Alamofire.request(makeURLRequest(
      url: url,
      method: method,
      headers: headers))

    if let cred = credential {
       request = request.authenticate(usingCredential: cred)
    }

    if let prog = onProgress {
      request.progress(prog)
    }

    let promise = Future<NSHTTPURLResponse>.promise()

    request.response(
      queue: QueueExecution.backgroundQueue,
      serializer: Alamofire.Request.responseDataSerializer(),
      completionHandler: { _, response, _, error in
        if let err = error {
          promise.reject(Errors.describeErrorForNSURLRequest(err))
        } else if let res = response {
          if self.isSuccessStatusCode(res.statusCode) {
            promise.resolve(res)
          } else {
            promise.reject(res)
          }
        } else {
          promise.reject("Unknown request error for \(method) \(url)")
        }
      })

    return promise
  }

  func head(
    url: NSURL,
    headers: Headers = [:],
    credential: NSURLCredential? = nil)
    -> Future<NSHTTPURLResponse>
  {
    return request(.HEAD, url: url, headers: headers, credential: credential)
  }

  func download(
    url: NSURL,
    to destination: NSURL,
    headers: Headers = [:],
    credential: NSURLCredential? = nil,
    onProgress: OnProgressCallback? = nil)
    -> Future<NSURL>
  {
    var request = Alamofire.download(makeURLRequest(url: url, headers: headers), { _, _ in destination })

    if let cred = credential {
      request = request.authenticate(usingCredential: cred)
    }

    if let prog = onProgress {
      request.progress(prog)
    }

    let promise = Future<NSURL>.promise()

    request.response(
      queue: QueueExecution.backgroundQueue,
      serializer: Alamofire.Request.responseDataSerializer(),
      completionHandler: { _, response, _, error in
        if let err = error {
          promise.reject(Errors.describeErrorForNSURLRequest(err))
        } else if let res = response {
          if self.isSuccessStatusCode(res.statusCode) {
            promise.resolve(destination)
          } else {
            promise.reject(res)
          }
        } else {
          promise.reject("Unknown download error for \(url)")
        }
      })

    return promise
  }

  // MARK: Helpers

  private func makeURLRequest(
    #url: NSURL,
    method: Method = .GET,
    headers: Headers = [:])
    -> NSURLRequest
  {
    let request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = method.rawValue
    for (headerName, headerValue) in DefaultHeaders {
      request.setValue(headerValue, forHTTPHeaderField: headerName)
    }
    for (headerName, headerValue) in headers {
      request.setValue(headerValue, forHTTPHeaderField: headerName)
    }
    return request
  }

  private func isSuccessStatusCode(code: Int) -> Bool {
    return contains(SuccessStatusCodes, code)
  }

  enum Method: String {
    case HEAD = "HEAD"
    case GET = "GET"
  }
}
