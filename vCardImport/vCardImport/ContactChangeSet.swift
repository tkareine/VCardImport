import Foundation
import AddressBook

struct ContactChangeSet {
  static let MultiValuePropertiesToCheck = [
    kABPersonPhoneProperty
  ]

  let name: ContactName
  let multiValueChanges: [ABPropertyID: [(String, String)]]

  static func resolve(
    name: ContactName,
    oldRecord: ABRecord,
    newRecord: ABRecord)
    -> ContactChangeSet?
  {
    var multiValueChanges: [ABPropertyID: [(String, String)]] = [:]

    for prop in MultiValuePropertiesToCheck {
      let oldMV = Contacts.getMultiValueProperty(prop, ofRecord: oldRecord)
      let newMV = Contacts.getMultiValueProperty(prop, ofRecord: newRecord)

      let oldValues = oldMV.map { $0.1 }
      var changesByLabel: [(String, String)] = []

      for newLabelAndValue in newMV {
        let (newLabel, newValue) = newLabelAndValue
        if !contains(oldValues, newValue) {
          changesByLabel.append(newLabelAndValue)
        }
      }

      if !changesByLabel.isEmpty {
        multiValueChanges[prop] = changesByLabel
      }
    }

    return multiValueChanges.isEmpty
      ? nil
      : ContactChangeSet(name: name, multiValueChanges: multiValueChanges)
  }
}
