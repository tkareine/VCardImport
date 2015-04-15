import AddressBook
import Foundation
import MiniFuture

class AddressBook {
  private let addressBook: ABAddressBook!

  var _abAddressBook: ABAddressBook {
    return addressBook
  }

  var hasUnsavedChanges: Bool {
    return ABAddressBookHasUnsavedChanges(addressBook)
  }

  private init?(error: NSErrorPointer) {
    func makeABAddressBook() -> ABAddressBook? {
      var abError: Unmanaged<CFError>?
      let abPtr: Unmanaged<ABAddressBook>? = ABAddressBookCreateWithOptions(nil, &abError)

      if let ab = abPtr {
        return ab.takeRetainedValue()
      }

      if error != nil && abError != nil {
        error.memory = Errors.fromCFError(abError!.takeRetainedValue())
      }

      return nil
    }

    func requestAuthorizationAndWaitResult(addressBook: ABAddressBook) -> ABAuthorizationStatus {
      var authResolution = false
      let semaphore = Semaphore()

      ABAddressBookRequestAccessWithCompletion(addressBook) { isGranted, _error in
        authResolution = isGranted
        semaphore.signal()
      }

      semaphore.wait(timeout: 30_000)

      return authResolution ? .Authorized : .Denied
    }

    var addressBookUsedForAuthorization: ABAddressBook?
    var authStatus = ABAddressBookGetAuthorizationStatus()

    if authStatus == .NotDetermined {
      if let ab: ABAddressBook = makeABAddressBook() {
        addressBookUsedForAuthorization = ab
        authStatus = requestAuthorizationAndWaitResult(ab)
      } else {
        addressBook = nil
        return nil
      }
    }

    if authStatus != .Authorized {
      if error != nil {
        error.memory = Errors.addressBookAccessDeniedOrRestricted()
      }
      addressBook = nil
      return nil
    }

    // is not already authorized?
    if addressBookUsedForAuthorization == nil {
      if let ab: ABAddressBook = makeABAddressBook() {
        addressBook = ab
      } else {
        addressBook = nil
        return nil
      }
    } else {
      addressBook = addressBookUsedForAuthorization
    }
  }

  func loadRecords() -> [ABRecord] {
    let defaultSource: ABRecord = ABAddressBookCopyDefaultSource(addressBook).takeRetainedValue()
    return ABAddressBookCopyArrayOfAllPeopleInSource(addressBook, defaultSource)
      .takeRetainedValue() as [ABRecord]
  }

  func addRecords(records: [ABRecord], error: NSErrorPointer) -> Bool {
    for record in records {
      var abError: Unmanaged<CFError>?

      let isAdded = ABAddressBookAddRecord(addressBook, record, &abError)

      if !isAdded {
        if error != nil && abError != nil {
          error.memory = Errors.fromCFError(abError!.takeRetainedValue())
        }

        return false
      }
    }

    return true
  }

  func save(#error: NSErrorPointer) -> Bool {
    var abError: Unmanaged<CFError>?
    let isSaved = ABAddressBookSave(addressBook, &abError)

    if !isSaved {
      if abError != nil {
        error.memory = Errors.fromCFError(abError!.takeRetainedValue())
      }

      return false
    }

    return true
  }

  class func sharedInstance(#error: NSErrorPointer) -> AddressBook? {
    struct Static {
      static var instance: AddressBook?
      static var error: NSError?
      static var token: QueueExecution.OnceToken = 0
    }

    QueueExecution.once(&Static.token) {
      var err: NSError?
      if let ab = AddressBook(error: &err) {
        Static.instance = ab
      }
      if let e = err {
        Static.error = err
      }
    }

    error.memory = Static.error
    return Static.instance
  }
}
