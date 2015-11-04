import Foundation

private func getDefaultUserAgent() -> String {
  let regex = try! NSRegularExpression(pattern: "\\s+", options: .CaseInsensitive)

  func withoutWhitespace(string: String) -> String {
    return regex.stringByReplacingMatchesInString(
      string,
      options: NSMatchingOptions(),
      range: NSMakeRange(0, string.characters.count),
      withTemplate: "")
  }

  return "\(withoutWhitespace(Config.Executable))/\(Config.BundleIdentifier) (\(Config.Version); OS \(Config.OS))"
}

private let DefaultHeaders = [
  "User-Agent": getDefaultUserAgent()
]

struct HTTPRequest {
  typealias Headers = [String: String]
  typealias ProgressBytes = (bytes: Int64, totalBytes: Int64, totalBytesExpected: Int64)
  typealias OnProgressCallback = ProgressBytes -> Void

  enum Method: String {
    case HEAD = "HEAD"
    case GET = "GET"
  }

  static func makeURLRequest(
    url url: NSURL,
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
}
