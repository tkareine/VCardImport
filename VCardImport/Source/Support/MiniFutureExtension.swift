import Foundation
import MiniFuture

extension PromiseFuture {
  func reject(response: NSHTTPURLResponse) {
    let statusDesc = NSHTTPURLResponse.localizedStringForStatusCode(response.statusCode).capitalized
    reject("\(statusDesc) (\(response.statusCode))")
  }
}
