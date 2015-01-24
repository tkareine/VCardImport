import Foundation
import Alamofire

class URLConnection {
  typealias Headers = [String: String]

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

  func request(method: Method, url: NSURL, headers: Headers = [:])
    -> Future<NSHTTPURLResponse>
  {
    let request = makeRequest(url: url, method: method, headers: headers)
    let promise = Future<NSHTTPURLResponse>.promise()
    Alamofire
      .request(request)
      .response(
        queue: QueueExecution.backgroundQueue,
        serializer: Alamofire.Request.responseDataSerializer(),
        completionHandler: { request, response, data, error in
          if error != nil {
            promise.reject(Config.Net.GenericErrorDescription)
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

  func head(url: NSURL, headers: Headers = [:]) -> Future<NSHTTPURLResponse>
  {
    return request(.HEAD, url: url, headers: headers)
  }

  func download(url: NSURL, to destination: NSURL, headers: Headers = [:])
    -> Future<NSURL>
  {
    let request = makeRequest(url: url, headers: headers)
    let promise = Future<NSURL>.promise()
    Alamofire
      .download(request, { _, _ in destination })
      .response(
        queue: QueueExecution.backgroundQueue,
        serializer: Alamofire.Request.responseDataSerializer(),
        completionHandler: { request, response, _, error in
          if error != nil {
            promise.reject(Config.Net.GenericErrorDescription)
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

  private func makeRequest(
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
