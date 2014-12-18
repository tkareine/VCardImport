import Foundation
import AddressBook

struct Errors {
  static let domain = "org.tkareine.vCardImport.ErrorDomain"
  static let titleKey = "VCardErrorTitle"

  static func addressBookAccessDeniedOrResticted() -> NSError {
    return vcardError(
      code: 5,
      failureReason: "Access error",
      description: "The application needs access to Contacts, but the access is denied or restricted. Please allow access in System Settings.")
  }

  static func addressBookFailedToUpdateContact(
    #name: String,
    property: ABPropertyID)
    -> NSError
  {
    let propDesc = describeAddressBookProperty(property)
    return vcardError(
      code: 7,
      failureReason: "Address book update error",
      description: "Failed in updating property \(propDesc) for contact \(name)")
  }

  static func fromCFError(error: CFError) -> NSError {
    return NSError(
      domain: CFErrorGetDomain(error),
      code: CFErrorGetCode(error),
      userInfo: CFErrorCopyUserInfo(error))
  }

  private static func vcardError(#code: Int, failureReason: String, description: String) -> NSError {
    let userInfo = [
      NSLocalizedFailureReasonErrorKey: failureReason,
      NSLocalizedDescriptionKey: description
    ]
    return NSError(domain: domain, code: code, userInfo: userInfo)
  }

  private static func describeAddressBookProperty(property: ABPropertyID) -> String {
    switch property {
    case kABPersonPhoneProperty:
      return "phone"
    default:
      return "unknown"
    }
  }
}
