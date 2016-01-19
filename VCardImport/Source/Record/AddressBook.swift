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

  private init() throws {
    func makeABAddressBook() throws -> ABAddressBook {
      var abError: Unmanaged<CFError>?
      let abPtr: Unmanaged<ABAddressBook>? = ABAddressBookCreateWithOptions(nil, &abError)

      guard let ab = abPtr else {
        if let err = abError {
          throw Errors.fromCFError(err.takeRetainedValue())
        } else {
          throw Errors.migration("Failed to create ABAddressBook")
        }
      }

      return ab.takeRetainedValue()
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

    let authStatus = ABAddressBookGetAuthorizationStatus()

    guard authStatus == .NotDetermined || authStatus == .Authorized else {
      addressBook = nil
      throw Errors.addressBookAccessDeniedOrRestricted()
    }

    do {
      addressBook = try makeABAddressBook()
    } catch {
      addressBook = nil
      throw error
    }

    if authStatus == .NotDetermined {
      if requestAuthorizationAndWaitResult(addressBook) != .Authorized {
        throw Errors.addressBookAccessDeniedOrRestricted()
      }
    }
  }

  func loadRecords() -> [ABRecord] {
    let defaultSource: ABRecord = ABAddressBookCopyDefaultSource(addressBook).takeRetainedValue()
    return ABAddressBookCopyArrayOfAllPeopleInSource(addressBook, defaultSource)
      .takeRetainedValue() as [ABRecord]
  }

  func addRecord(record: ABRecord) throws {
    var abError: Unmanaged<CFError>?
    let isAdded = ABAddressBookAddRecord(addressBook, record, &abError)

    guard isAdded else {
      if let err = abError {
        throw Errors.fromCFError(err.takeRetainedValue())
      } else {
        throw Errors.migration("Failed to add record to address book")
      }
    }
  }

  func save() throws {
    var abError: Unmanaged<CFError>?
    let isSaved = ABAddressBookSave(addressBook, &abError)

    guard isSaved else {
      if let err = abError {
        throw Errors.fromCFError(err.takeRetainedValue())
      } else {
        throw Errors.migration("Failed to save address book")
      }
    }
  }

  static func sharedInstance() throws -> AddressBook {
    struct Static {
      static var instance: AddressBook?
      static var error: ErrorType?
      static var token: QueueExecution.OnceToken = 0
    }

    QueueExecution.once(&Static.token) {
      do {
        let ab = try AddressBook()
        Static.instance = ab
      } catch {
        Static.error = error
      }
    }

    guard let inst = Static.instance else {
      throw Static.error!
    }

    return inst
  }
}
