import Foundation
import Alamofire
import MiniFuture

class URLConnection: URLConnectable {
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
    method: Request.Method,
    url: NSURL,
    headers: Request.Headers = [:],
    credential: NSURLCredential? = nil,
    onProgress: Request.OnProgressCallback? = nil)
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
      queue: QueueExecution.concurrentQueue,
      serializer: Alamofire.Request.responseDataSerializer(),
      completionHandler: { _, response, _, error in
        if let err = error {
          NSLog("%@ request error <%@>: %@", method.rawValue, url, err)
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
    headers: Request.Headers = [:],
    credential: NSURLCredential? = nil)
    -> Future<NSHTTPURLResponse>
  {
    return request(.HEAD, url: url, headers: headers, credential: credential)
  }

  func download(
    url: NSURL,
    to destination: NSURL,
    headers: Request.Headers = [:],
    credential: NSURLCredential? = nil,
    onProgress: Request.OnProgressCallback? = nil)
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
      queue: QueueExecution.concurrentQueue,
      serializer: Alamofire.Request.responseDataSerializer(),
      completionHandler: { _, response, _, error in
        if let err = error {
          NSLog("Download error <%@>: %@", url, err)
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
    method: Request.Method = .GET,
    headers: Request.Headers = [:])
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
}
