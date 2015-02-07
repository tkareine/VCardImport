import Foundation
import AddressBook

class RecordName: Hashable, Equatable, Printable {
  var hashValue: Int {
    fatalError("must be overridden")
  }

  var description: String {
    fatalError("must be overridden")
  }

  class func of(record: ABRecord) -> RecordName? {
    let kind = (Records.getSingleValueProperty(kABPersonKindProperty, of: record) as NSNumber) ?? (kABPersonKindPerson as NSNumber)

    if kind.isEqualToNumber(kABPersonKindPerson) {
      let fn = (Records.getSingleValueProperty(kABPersonFirstNameProperty, of: record) as String?) ?? ""
      let ln = (Records.getSingleValueProperty(kABPersonLastNameProperty, of: record) as String?) ?? ""

      if fn.isEmpty && ln.isEmpty {
        return nil
      } else {
        return PersonRecordName(firstName: fn, lastName: ln)
      }
    } else {
      let n = (Records.getSingleValueProperty(kABPersonOrganizationProperty, of: record) as String?) ?? ""

      if n.isEmpty {
        return nil
      } else {
        return OrganizationRecordName(name: n)
      }
    }
  }
}

class PersonRecordName: RecordName {
  let firstName: String
  let lastName: String

  override var hashValue: Int {
    var hash = 17
    hash = 31 &* hash &+ firstName.hashValue
    hash = 31 &* hash &+ lastName.hashValue
    return hash
  }

  override var description: String {
    return "\(lastName), \(firstName)"
  }

  init(firstName: String, lastName: String) {
    self.firstName = firstName
    self.lastName = lastName
  }
}

class OrganizationRecordName: RecordName {
  let name: String

  override var hashValue: Int {
    return 31 &* 17 &+ name.hashValue
  }

  override var description: String {
    return name
  }

  init(name: String) {
    self.name = name
  }
}

func ==(lhs: RecordName, rhs: RecordName) -> Bool {
  if let lh = lhs as? PersonRecordName {
    if let rh = rhs as? PersonRecordName {
      return lh.firstName == rh.firstName && lh.lastName == rh.lastName
    }
  }
  if let lh = lhs as? OrganizationRecordName {
    if let rh = rhs as? OrganizationRecordName {
      return lh.name == rh.name
    }
  }
  return false
}
