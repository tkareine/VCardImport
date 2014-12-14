import Foundation

class ContactName: Hashable, Equatable {
  let firstName: String
  let lastName: String

  var hashValue: Int {
    var hash = 17
    hash = 31 &* hash &+ firstName.hashValue
    hash = 31 &* hash &+ lastName.hashValue
    return hash
  }

  init(firstName: String, lastName: String) {
    self.firstName = firstName
    self.lastName = lastName
  }
}

func ==(lhs: ContactName, rhs: ContactName) -> Bool {
  return lhs.firstName == rhs.firstName && lhs.lastName == rhs.lastName
}
