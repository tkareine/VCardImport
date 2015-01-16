import Foundation
import AddressBook

struct Errors {
  static let domain = "org.tkareine.VCardImport.ErrorDomain"
  static let titleKey = "VCardErrorTitle"

  static func addressBookAccessDeniedOrResticted() -> NSError {
    return vcardError(
      code: 5,
      failureReason: "Contacts Access Error",
      description: "The application needs access to Contacts, but the access is denied or restricted. Please allow access in System Settings.")
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

  static func rejectPromise<T>(promise: PromiseFuture<T>, _ error: NSError) {
    promise.reject("\(error.localizedFailureReason): \(error.localizedDescription)")
  }

  static func rejectPromise<T>(promise: PromiseFuture<T>, _ response: NSHTTPURLResponse) {
    let statusDesc = NSHTTPURLResponse.localizedStringForStatusCode(response.statusCode)
    promise.reject("(\(response.statusCode)) \(statusDesc)")
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
    case kABPersonMiddleNameProperty:
      return "middle name"
    case kABPersonJobTitleProperty:
      return "job title"
    case kABPersonDepartmentProperty:
      return "department"
    case kABPersonOrganizationProperty:
      return "organization"
    case kABPersonEmailProperty:
      return "email"
    case kABPersonPhoneProperty:
      return "phone"
    case kABPersonURLProperty:
      return "URL"
    case kABPersonAddressProperty:
      return "address"
    default:
      return "unknown"
    }
  }
}
