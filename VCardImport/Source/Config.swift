import UIKit

private func getBundleInfo()
  -> (executable: String, bundleId: String, version: String)
{
  var executable: String?
  var bundleId: String?
  var version: String?

  if let info = NSBundle.mainBundle().infoDictionary {
    if let data = info[kCFBundleExecutableKey] as? String {
      executable = data
    }
    if let data = info[kCFBundleIdentifierKey] as? String {
      bundleId = data
    }
    if let data = info[kCFBundleVersionKey] as? String {
      version = data
    }
  }

  return (
    executable ?? "Unknown",
    bundleId   ?? "org.tkareine.VCardImport",
    version    ?? "Unknown"
  )
}

private let BundleInfo = getBundleInfo()

struct Config {
  static let AppTitle = "vCard Import"

  static let Executable = BundleInfo.executable

  static let BundleIdentifier = BundleInfo.bundleId

  static let Version = BundleInfo.version

  static let OS = NSProcessInfo.processInfo().operatingSystemVersionString

  static let VCardHTTPHeaders = [
    "Accept": "text/vcard,text/x-vcard,text/directory;profile=vCard;q=0.9,text/directory;q=0.8,*/*;q=0.7"
  ]

  struct UI {
    static let SourcesCellReuseIdentifier = "SourcesCellReuseIdentifier"
    static let CellTextColorEnabled = UIColor.blackColor()
    static let CellTextColorDisabled = UIColor.grayColor()
    static let ValidationBorderColor = UIColor(red: 1.0, green: 0, blue: 0, alpha: 0.6).CGColor
    static let ValidationBorderWidth: CGFloat = 2.0
    static let ValidationCornerRadius: CGFloat = 5.0
  }
}
