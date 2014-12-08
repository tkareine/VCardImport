import Foundation

struct Errors {
  static let domain = "org.tkareine.vCardImport.ErrorDomain"
  static let titleKey = "VCardErrorTitle"

  static func addressBookAccessDeniedOrResticted() -> NSError {
    return vcardError(
      code: 5,
      failureReason: "Access error",
      description: "The application needs access to Contacts, but the access is denied or restricted. Please allow access in System Settings.")
  }

  private static func vcardError(#code: Int, failureReason: String, description: String) -> NSError {
    let userInfo = [
      NSLocalizedFailureReasonErrorKey: failureReason,
      NSLocalizedDescriptionKey: description
    ]
    return NSError(domain: domain, code: code, userInfo: userInfo)
  }
}
