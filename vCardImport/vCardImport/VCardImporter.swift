import Foundation
import AddressBook

let sharedVCardImporter = VCardImporter()

class VCardImporter {
  private init() {}

  func importFrom(url: NSURL, error: NSErrorPointer) -> Bool {
    return importRecords(loadExampleContacts(), error: error)
  }

  private func importRecords(records: [ABRecord], error: NSErrorPointer) -> Bool {
    if records.isEmpty {
      return true
    }

    var authStatus = ABAddressBookGetAuthorizationStatus()

    if (authStatus == .NotDetermined) {
      authStatus = askAddressBookAuthorizationSync(error)
    }

    switch ABAddressBookGetAuthorizationStatus() {
    case .Authorized:
      NSLog("AB access is authorized")
      return true
    default:
      NSLog("AB access is denied or restricted")
      if error != nil {
        error.memory = VCardErrors.addressBookAccessDeniedOrResticted()
      }
      return false
    }

    // TODO: loop over records, add them to address book
  }

  private func loadExampleContacts() -> [ABRecord] {
    let vcardPath = NSBundle.mainBundle().pathForResource("example-contacts", ofType: "vcf")
    let vcardData = NSData(contentsOfFile: vcardPath!)
    return ABPersonCreatePeopleInSourceWithVCardRepresentation(nil, vcardData).takeRetainedValue()
  }

  private func newAddressBook(error: NSErrorPointer) -> ABAddressBook? {
    var addressBookError: Unmanaged<CFError>?
    let addressBookRef: Unmanaged<ABAddressBook>? = ABAddressBookCreateWithOptions(nil, &addressBookError)

    if let abPtr: Unmanaged<ABAddressBook> = addressBookRef {
      return abPtr.takeRetainedValue()
    } else if let abErr: Unmanaged<CFError> = addressBookError {
      if (error != nil) {
        let cferr = abErr.takeUnretainedValue()
        error.memory = NSError(domain: CFErrorGetDomain(cferr),
          code: CFErrorGetCode(cferr),
          userInfo: CFErrorCopyUserInfo(cferr))
      }
    }
    return nil
  }

  private func askAddressBookAuthorizationSync(error: NSErrorPointer) -> ABAuthorizationStatus {
    var authResolution = false
    let semaphore = dispatch_semaphore_create(0)

    ABAddressBookRequestAccessWithCompletion(newAddressBook(error)) { (granted: Bool, _error) in
      authResolution = granted
      dispatch_semaphore_signal(semaphore)
    }

    let timeout = dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) * Int64(30))
    dispatch_semaphore_wait(semaphore, timeout)

    return authResolution ? .Authorized : .Denied
  }
}
