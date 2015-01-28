import Foundation
import AddressBook

class RecordName: Hashable, Equatable, Printable {
  let firstName: String
  let lastName: String

  var hashValue: Int {
    var hash = 17
    hash = 31 &* hash &+ firstName.hashValue
    hash = 31 &* hash &+ lastName.hashValue
    return hash
  }

  var description: String {
    return "\(lastName), \(firstName)"
  }

  init(firstName: String, lastName: String) {
    self.firstName = firstName
    self.lastName = lastName
  }

  convenience init?(ofRecord record: ABRecord) {
    let fn = (Records.getSingleValueProperty(kABPersonFirstNameProperty, of: record) as String?) ?? ""
    let ln = (Records.getSingleValueProperty(kABPersonLastNameProperty, of: record) as String?) ?? ""

    self.init(firstName: fn, lastName: ln)

    if self.firstName.isEmpty && self.lastName.isEmpty {
      return nil
    }
  }
}

func ==(lhs: RecordName, rhs: RecordName) -> Bool {
  return lhs.firstName == rhs.firstName && lhs.lastName == rhs.lastName
}
