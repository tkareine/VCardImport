import UIKit

struct Config {
  static let AppTitle = "vCard Import"

  static let AppInfo: String = {
    if let info = NSBundle.mainBundle().infoDictionary {
      let executable: AnyObject = info[kCFBundleExecutableKey] ?? "Unknown"
      let bundle: AnyObject = info[kCFBundleIdentifierKey] ?? "Unknown"
      let version: AnyObject = info[kCFBundleVersionKey] ?? "Unknown"
      let os: AnyObject = NSProcessInfo.processInfo().operatingSystemVersionString ?? "Unknown"
      return "\(executable)/\(bundle) (\(version); OS \(os))"
    } else {
      return AppTitle
    }
  }()

  struct UI {
    static let SourcesCellReuseIdentifier = "SourcesCellReuseIdentifier"
    static let CellTextColorEnabled = UIColor.blackColor()
    static let CellTextColorDisabled = UIColor.grayColor()
  }
}
