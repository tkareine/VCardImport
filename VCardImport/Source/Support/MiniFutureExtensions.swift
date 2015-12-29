import Foundation
import MiniFuture

extension Future {
  class func makeSwitchLatest() -> (Future<T> -> Future<T>) {
    var lastFuture: Future<T>?

    func latest(future: Future<T>) -> Future<T> {
      lastFuture = future
      let grd = Future<T>.promise()
      future.onComplete { result in
        if future === lastFuture {
          grd.complete(result)
        }
      }
      return grd
    }

    return latest
  }
}
