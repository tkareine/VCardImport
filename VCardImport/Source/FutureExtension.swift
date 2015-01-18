import Foundation

extension PromiseFuture {
  func reject(response: NSHTTPURLResponse) {
    let statusDesc = NSHTTPURLResponse.localizedStringForStatusCode(response.statusCode)
    reject("\(statusDesc) (\(response.statusCode))")
  }
}
