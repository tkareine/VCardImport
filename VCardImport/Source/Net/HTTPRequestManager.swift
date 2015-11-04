import Foundation
import Alamofire
import MiniFuture

class HTTPRequestManager: HTTPRequestable {
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
    method: HTTPRequest.Method,
    url: NSURL,
    headers: HTTPRequest.Headers = [:],
    credential: NSURLCredential? = nil,
    onProgress: HTTPRequest.OnProgressCallback? = nil)
    -> Future<NSHTTPURLResponse>
  {
    var request = manager.request(HTTPRequest.makeURLRequest(
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
      completionHandler: { _, response, _, error in
        if let res = response {
          if HTTPResponse.isSuccessStatusCode(res.statusCode) {
            promise.resolve(res)
          } else {
            promise.reject(Errors.urlRequestFailed(res))
          }
        } else if let err = error {
          NSLog("%@ request error <%@>: %@", method.rawValue, url, err)
          promise.reject(Errors.urlRequestFailed(err))
        } else {
          promise.reject(Errors.urlRequestFailed("Unknown request error for \(method) \(url)"))
        }
      })

    return promise
  }

  func head(
    url: NSURL,
    headers: HTTPRequest.Headers = [:],
    credential: NSURLCredential? = nil)
    -> Future<NSHTTPURLResponse>
  {
    return request(.HEAD, url: url, headers: headers, credential: credential)
  }

  func download(
    url: NSURL,
    to destination: NSURL,
    headers: HTTPRequest.Headers = [:],
    credential: NSURLCredential? = nil,
    onProgress: HTTPRequest.OnProgressCallback? = nil)
    -> Future<NSURL>
  {
    var request = manager.download(HTTPRequest.makeURLRequest(url: url, headers: headers), destination: { _, _ in destination })

    if let cred = credential {
      request = request.authenticate(usingCredential: cred)
    }

    if let prog = onProgress {
      request.progress(prog)
    }

    let promise = Future<NSURL>.promise()

    request.response(
      queue: QueueExecution.concurrentQueue,
      completionHandler: { _, response, _, error in
        if let res = response {
          if HTTPResponse.isSuccessStatusCode(res.statusCode) {
            promise.resolve(destination)
          } else {
            promise.reject(Errors.urlRequestFailed(res))
          }
        } else if let err = error {
          NSLog("Download error <%@>: %@", url, err)
          promise.reject(Errors.urlRequestFailed(err))
        } else {
          promise.reject(Errors.urlRequestFailed("Unknown download error for \(url)"))
        }
      })

    return promise
  }
}
