import AddressBook
import Foundation

extension AddressBook {
  func loadRecordsWithName(name: String) -> [ABRecord] {
    return ABAddressBookCopyPeopleWithName(_abAddressBook, name).takeRetainedValue() as [ABRecord]
  }

  func removeRecords(records: [ABRecord]) throws {
    var error: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
    for record in records {
      var abError: Unmanaged<CFError>?

      let isRemoved = ABAddressBookRemoveRecord(_abAddressBook, record, &abError)

      if !isRemoved {
        if true && abError != nil {
          error = Errors.fromCFError(abError!.takeRetainedValue())
        }

        throw error
      }
    }
  }
}
