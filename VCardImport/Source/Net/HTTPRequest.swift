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
    case None = "None"
    case BasicAuth = "BasicAuth"
    case PostForm = "PostForm"

    static let allValues = [None, BasicAuth, PostForm]

    var shortDescription: String {
      switch self {
      case .None:
        return "None"
      case .BasicAuth:
        return "HTTP Basic Auth"
      case .PostForm:
        return "Post Form"
      }
    }

    var longDescription: String? {
      switch self {
      case .None:
        return "For public resources requiring no authentication."
      case .BasicAuth:
        return "The standard HTTP authentication with username and password."
      case .PostForm:
        return "Login form authentication with username and password. The app sends the credentials in a POST request to a login URL you provide. The server must establish a cookie based session upon successful authentication. The login URL must differ from the vCard file URL: authentication outcome detection depends on it."
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
