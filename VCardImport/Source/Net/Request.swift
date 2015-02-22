import Foundation

struct Request {
  typealias Headers = [String: String]
  typealias ProgressBytes = (bytes: Int64, totalBytes: Int64, totalBytesExpected: Int64)
  typealias OnProgressCallback = ProgressBytes -> Void

  enum Method: String {
    case HEAD = "HEAD"
    case GET = "GET"
  }
}
