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
  typealias Parameters = [String: AnyObject]
  typealias ProgressBytes = (bytes: Int64, totalBytes: Int64, totalBytesExpected: Int64)
  typealias OnProgressCallback = ProgressBytes -> Void

  enum RequestMethod: String {
    case HEAD = "HEAD"
    case GET = "GET"
    case POST = "POST"
  }

  enum AuthenticationMethod: String {
    case HTTPAuth = "HTTPAuth"
    case PostForm = "PostForm"

    static let allValues = [HTTPAuth, PostForm]

    var shortDescription: String {
      switch self {
      case .HTTPAuth:
        return "HTTP Basic Auth"
      case .PostForm:
        return "Post Form"
      }
    }

    var longDescription: String {
      switch self {
      case .HTTPAuth:
        return "The standard HTTP authentication with username and password."
      case .PostForm:
        return "Cookie based HTTP session authentication by login form submission with POST method, sending username and password as URL encoded values. The URL for the login submission must be separate from the vCard file URL. The app employs detection for authentication outcome, which is not fully reliable."
      }
    }
  }

  static func makeURLRequest(
    method method: RequestMethod = .GET,
    url: NSURL,
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
