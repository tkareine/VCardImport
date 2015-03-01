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

  init?(error: NSErrorPointer) {
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

    func requestAuthorizationAndWaitResult() -> ABAuthorizationStatus {
      var authResolution = false
      let semaphore = Semaphore()

      ABAddressBookRequestAccessWithCompletion(addressBook) { isGranted, _error in
        authResolution = isGranted
        semaphore.signal()
      }

      semaphore.wait(timeout: 30_000)

      return authResolution ? .Authorized : .Denied
    }

    var authStatus = ABAddressBookGetAuthorizationStatus()

    if authStatus == .NotDetermined {
      if let ab: ABAddressBook = makeABAddressBook() {
        addressBook = ab
        authStatus = requestAuthorizationAndWaitResult()
      } else {
        return nil
      }
    }

    if authStatus != .Authorized {
      if error != nil {
        error.memory = Errors.addressBookAccessDeniedOrRestricted()
      }

      return nil
    }

    // is already authorized?
    if addressBook == nil {
      if let ab: ABAddressBook = makeABAddressBook() {
        addressBook = ab
      } else {
        return nil
      }
    }
  }

  func loadRecords() -> [ABRecord] {
    let defaultSource: ABRecord = ABAddressBookCopyDefaultSource(addressBook).takeRetainedValue()
    return ABAddressBookCopyArrayOfAllPeopleInSource(addressBook, defaultSource)
      .takeRetainedValue()
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
}
