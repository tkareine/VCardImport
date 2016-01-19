import Foundation
import Alamofire
import MiniFuture

class HTTPSession: HTTPRequestable {
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

  func head(
    url: NSURL,
    headers: HTTPRequest.Headers,
    credential: NSURLCredential? = nil)
    -> Future<NSHTTPURLResponse>
  {
    let managedRequest = manager.request(HTTPRequest.makeURLRequest(
      method: .HEAD,
      url: url,
      headers: headers))

    if let cred = credential {
       managedRequest.authenticate(usingCredential: cred)
    }

    let promise = Future<NSHTTPURLResponse>.promise()

    managedRequest.response(
      queue: QueueExecution.concurrentQueue,
      completionHandler: makeResponseCompletionHandler(
        method: .HEAD,
        url: url,
        promise: promise))

    return promise
  }

  func post(
    url: NSURL,
    headers: HTTPRequest.Headers,
    parameters: HTTPRequest.Parameters)
    -> Future<NSHTTPURLResponse>
  {
    let (urlRequest, error) = ParameterEncoding.URL.encode(
      HTTPRequest.makeURLRequest(
        method: .POST,
        url: url,
        headers: headers),
      parameters: parameters)

    if let err = error {
      fatalError("URL encoding error for parameters \(parameters): \(err)")
    }

    let promise = Future<NSHTTPURLResponse>.promise()

    manager.request(urlRequest).response(
      queue: QueueExecution.concurrentQueue,
      completionHandler: makeResponseCompletionHandler(
        method: .POST,
        url: url,
        promise: promise))

    return promise
  }

  func download(
    url: NSURL,
    to destination: NSURL,
    headers: HTTPRequest.Headers,
    credential: NSURLCredential? = nil,
    onProgress: HTTPRequest.OnDownloadProgressCallback? = nil)
    -> Future<NSURL>
  {
    let managedRequest = manager.download(
      HTTPRequest.makeURLRequest(
        method: .GET,
        url: url,
        headers: headers),
      destination: { _, _ in destination })

    if let cred = credential {
      managedRequest.authenticate(usingCredential: cred)
    }

    if let prog = onProgress {
      managedRequest.progress(prog)
    }

    let promise = Future<NSURL>.promise()

    managedRequest.response(
      queue: QueueExecution.concurrentQueue,
      completionHandler: makeDownloadCompletionHandler(
        url: url,
        to: destination,
        promise: promise))

    return promise
  }

  // MARK: Helpers

  func makeResponseCompletionHandler(
    method method: HTTPRequest.RequestMethod,
    url: NSURL,
    promise: PromiseFuture<NSHTTPURLResponse>)
  (
    request: NSURLRequest?,
    response: NSHTTPURLResponse?,
    data: NSData?,
    error: NSError?)
  {
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
  }

  func makeDownloadCompletionHandler(
    url url: NSURL,
    to destination: NSURL,
    promise: PromiseFuture<NSURL>)
    (
    request: NSURLRequest?,
    response: NSHTTPURLResponse?,
    data: NSData?,
    error: NSError?)
  {
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
  }
}
