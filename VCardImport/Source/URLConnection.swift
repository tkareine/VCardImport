import Foundation

class URLConnection {
  private let session: NSURLSession

  init() {
    func makeUserAgentHeader() -> String {
      if let info = NSBundle.mainBundle().infoDictionary {
        let executable: AnyObject = info[kCFBundleExecutableKey] ?? "Unknown"
        let bundle: AnyObject = info[kCFBundleIdentifierKey] ?? "Unknown"
        let version: AnyObject = info[kCFBundleVersionKey] ?? "Unknown"
        let os: AnyObject = NSProcessInfo.processInfo().operatingSystemVersionString ?? "Unknown"
        var mutableUserAgent = NSMutableString(string: "\(executable)/\(bundle) (\(version); OS \(os))") as CFMutableString
        let transform = NSString(string: "Any-Latin; Latin-ASCII; [:^ASCII:] Remove") as CFString
        if CFStringTransform(mutableUserAgent, nil, transform, 0) == 1 {
          return mutableUserAgent as String
        }
      }
      return "vCardImport"
    }

    func makeHeaders() -> [String: String] {
      return [
        "Accept": "text/vcard,text/x-vcard,text/directory;profile=vCard;q=0.9,text/directory;q=0.8,*/*;q=0.7",
        "Accept-Encoding": "gzip,compress;q=0.9",
        "User-Agent": makeUserAgentHeader()
      ]
    }

    let config = NSURLSessionConfiguration.ephemeralSessionConfiguration()
    config.allowsCellularAccess = true
    config.timeoutIntervalForRequest = 60
    config.timeoutIntervalForResource = 60 * 60 * 10
    config.HTTPAdditionalHeaders = makeHeaders()

    let operationQueue = NSOperationQueue()
    operationQueue.qualityOfService = .UserInitiated
    operationQueue.maxConcurrentOperationCount = 6

    session = NSURLSession(configuration: config, delegate: nil, delegateQueue: operationQueue)
  }

  func download(url: NSURL, toDestination destinationURL: NSURL) -> Future<NSURL> {
    let promise = Future<NSURL>.promise()
    let request = NSURLRequest(URL: url)
    let task = session.downloadTaskWithRequest(request, completionHandler: { location, response, error in
      if let err = error {
        promise.reject("\(err.localizedFailureReason): \(err.localizedDescription)")
      } else if let res = response as? NSHTTPURLResponse {
        if res.statusCode == 200 {
          Files.moveFile(location, to: destinationURL)
          promise.resolve(destinationURL)
        } else {
          let statusDesc = NSHTTPURLResponse.localizedStringForStatusCode(res.statusCode)
          promise.reject("(\(res.statusCode)) \(statusDesc)")
        }
      } else {
        promise.reject("Unknown download error")
      }
    })
    task.resume()
    return promise
  }
}
