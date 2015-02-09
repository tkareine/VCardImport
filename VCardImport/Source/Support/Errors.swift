import Foundation
import AddressBook

struct Errors {
  private static let Domain = Config.BundleIdentifier + ".Error"

  static func addressBookAccessDeniedOrRestricted() -> NSError {
    return vcardError(
      code: 5,
      failureReason: "Contacts Access Error",
      description: "The application needs access to Contacts, but access is denied or restricted. Please allow access in System Settings.")
  }

  static func addressBookFailedToLoadVCardSource(reason: String) -> NSError {
    return vcardError(
      code: 6,
      failureReason: "VCard Download Error",
      description: "Download failed: \(reason)")
  }

  static func addressBookFailedToChangeRecord(
    #name: String,
    property: ABPropertyID)
    -> NSError
  {
    let propDesc = describeAddressBookProperty(property)
    return vcardError(
      code: 8,
      failureReason: "Contact Update Error",
      description: "Failed in updating \(propDesc) for contact \(name)")
  }

  static func fromCFError(error: CFError) -> NSError {
    return NSError(
      domain: CFErrorGetDomain(error),
      code: CFErrorGetCode(error),
      userInfo: CFErrorCopyUserInfo(error))
  }

  static func describeErrorForNSURLRequest(error: NSError) -> String {
    switch error.code {
    case NSURLErrorTimedOut | NSURLErrorUserCancelledAuthentication:
      return "Response timed out"
    case NSURLErrorCancelled:
      return "Cancelled (authentication rejected?)"
    case NSURLErrorNotConnectedToInternet | NSURLErrorNetworkConnectionLost:
      return "No internet connection"
    default:
      return Config.Net.GenericErrorDescription
    }
  }

  // MARK: Helpers

  private static func vcardError(#code: Int, failureReason: String, description: String) -> NSError {
    let userInfo = [
      NSLocalizedFailureReasonErrorKey: failureReason,
      NSLocalizedDescriptionKey: description
    ]
    return NSError(domain: Domain, code: code, userInfo: userInfo)
  }

  private static func describeAddressBookProperty(property: ABPropertyID) -> String {
    switch property {
    case kABPersonMiddleNameProperty:
      return "middle name"
    case kABPersonPrefixProperty:
      return "name prefix"
    case kABPersonSuffixProperty:
      return "name suffix"
    case kABPersonNicknameProperty:
      return "nickname"
    case kABPersonOrganizationProperty:
      return "organization"
    case kABPersonJobTitleProperty:
      return "job title"
    case kABPersonDepartmentProperty:
      return "department"
    case kABPersonEmailProperty:
      return "email"
    case kABPersonPhoneProperty:
      return "phone"
    case kABPersonURLProperty:
      return "URL"
    case kABPersonAddressProperty:
      return "address"
    case kABPersonInstantMessageProperty:
      return "instant message"
    case kABPersonSocialProfileProperty:
      return "social profile"
    default:
      return "unknown"
    }
  }
}
