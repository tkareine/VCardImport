import Foundation
import AddressBook

class RecordName: Hashable, Equatable, CustomStringConvertible {
  var hashValue: Int {
    fatalError("must be overridden")
  }

  var description: String {
    fatalError("must be overridden")
  }

  static func of(record: ABRecord, includePersonNickname: Bool = true)
    -> RecordName?
  {
    let kind = (Records.getSingleValueProperty(kABPersonKindProperty, of: record) as? NSNumber) ?? (kABPersonKindPerson as NSNumber)

    if kind.isEqualToNumber(kABPersonKindPerson) {
      let firstName = (Records.getSingleValueProperty(kABPersonFirstNameProperty, of: record) as? String) ?? ""
      let lastName = (Records.getSingleValueProperty(kABPersonLastNameProperty, of: record) as? String) ?? ""
      let nickname = includePersonNickname
        ? Records.getSingleValueProperty(kABPersonNicknameProperty, of: record) as? String ?? ""
        : ""

      if firstName.isEmpty && lastName.isEmpty && nickname.isEmpty {
        return nil
      } else {
        return PersonRecordName(
          firstName: firstName,
          lastName: lastName,
          nickname: nickname)
      }
    } else {
      let name = (Records.getSingleValueProperty(kABPersonOrganizationProperty, of: record) as? String) ?? ""

      if name.isEmpty {
        return nil
      } else {
        return OrganizationRecordName(name: name)
      }
    }
  }
}

class PersonRecordName: RecordName {
  let firstName: String
  let lastName: String
  let nickname: String

  override var hashValue: Int {
    var hash = 17
    hash = 31 &* hash &+ firstName.hashValue
    hash = 31 &* hash &+ lastName.hashValue
    hash = 31 &* hash &+ nickname.hashValue
    return hash
  }

  override var description: String {
    var str = "\(lastName), \(firstName)"
    if !nickname.isEmpty {
      str += " \"\(nickname)\""
    }
    return str
  }

  init(firstName: String, lastName: String, nickname: String) {
    self.firstName = firstName
    self.lastName = lastName
    self.nickname = nickname
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
  if let
    lh = lhs as? PersonRecordName,
    rh = rhs as? PersonRecordName
  {
    return lh.firstName == rh.firstName
        && lh.lastName == rh.lastName
        && lh.nickname == rh.nickname
  } else if let
    lh = lhs as? OrganizationRecordName,
    rh = rhs as? OrganizationRecordName
  {
    return lh.name == rh.name
  } else {
    return false
  }
}
