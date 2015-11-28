import UIKit

private func getBundleInfo()
  -> (executable: String, bundleId: String, version: String)
{
  var executable: String?
  var bundleId: String?
  var version: String?

  if let info = NSBundle.mainBundle().infoDictionary {
    if let data = info[kCFBundleExecutableKey as String] as? String {
      executable = data
    }
    if let data = info[kCFBundleIdentifierKey as String] as? String {
      bundleId = data
    }
    if let data = info[kCFBundleVersionKey as String] as? String {
      version = data
    }
  }

  return (
    executable ?? "vCard Turbo",
    bundleId   ?? "org.tkareine.vCard-Turbo",
    version    ?? "Unknown"
  )
}

private let BundleInfo = getBundleInfo()

struct Config {
  static let Executable = BundleInfo.executable

  static let BundleIdentifier = BundleInfo.bundleId

  static let Version = BundleInfo.version

  static let OS = NSProcessInfo.processInfo().operatingSystemVersionString

  struct Net {
    static let GenericErrorDescription = "Cannot reach URL"

    static let VCardHTTPHeaders = [
      "Accept": "text/vcard,text/x-vcard,text/directory;profile=vCard;q=0.9,text/directory;q=0.8,*/*;q=0.7"
    ]
  }

  struct Persistence {
    static let CredentialsKey = "Credentials"
    static let VCardSourcesKey = "VCardSources"
    static let VersionKey = "Version"
  }

  struct UI {
    static let AnimationDurationFadeMessage: NSTimeInterval = 0.5
    static let AnimationDelayFadeOutMessage: NSTimeInterval = 5
    static let TableCellHeaderTextColor = UIColor.blackColor()
    static let TableCellDescriptionTextColor = UIColor(white: 0.3, alpha: 1)
    static let TableCellDisabledTextColor = UIColor.grayColor()
    static let TintColor = UIColor(red: 0.000, green: 0.664, blue: 0.434, alpha: 1)  // #00AA6F
    static let ToolbarBackgroundColor = UIColor(white: 0.97, alpha: 1)
    static let ToolbarBorderColor = UIColor(white: 0.8, alpha: 1).CGColor
    static let ToolbarProgressTextColor = TableCellDescriptionTextColor
    static let ValidationBorderColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.6).CGColor
    static let ValidationBorderWidth: CGFloat = 2
    static let ValidationCornerRadius: CGFloat = 5
    static let ValidationThrottleInMS = 300
    static let VCardNewSourceHeader = "Add vCard Source"
    static let VCardSourceNoteText = "Specify vCard file URL at remote server you trust. Prefer secure connections with https URL. All contacts in the vCard file will be considered for importing."
  }
}
