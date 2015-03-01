import Foundation
import MiniFuture

extension Future {
  class func makeSwitchLatest() -> (Future<T> -> Future<T>) {
    var lastFuture: Future<T>?

    func latest(future: Future<T>) -> Future<T> {
      lastFuture = future
      let guard = Future<T>.promise()
      future.onComplete { result in
        if future === lastFuture {
          guard.complete(result)
        }
      }
      return guard
    }

    return latest
  }
}

extension PromiseFuture {
  func reject(response: NSHTTPURLResponse) {
    let statusDesc = NSHTTPURLResponse.localizedStringForStatusCode(response.statusCode).capitalized
    reject("\(statusDesc) (\(response.statusCode))")
  }
}
