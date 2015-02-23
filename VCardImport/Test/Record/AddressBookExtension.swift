import AddressBook
import Foundation

extension AddressBook {
  func loadRecordsWithName(name: String) -> [ABRecord] {
    return ABAddressBookCopyPeopleWithName(_abAddressBook, name).takeRetainedValue()
  }

  func removeRecords(records: [ABRecord], error: NSErrorPointer) -> Bool {
    for record in records {
      var abError: Unmanaged<CFError>?

      let isRemoved = ABAddressBookRemoveRecord(_abAddressBook, record, &abError)

      if !isRemoved {
        if error != nil && abError != nil {
          error.memory = Errors.fromCFError(abError!.takeRetainedValue())
        }

        return false
      }
    }

    return true
  }
}
