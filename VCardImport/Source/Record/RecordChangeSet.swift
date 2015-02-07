import Foundation
import AddressBook

struct RecordChangeSet {
  let record: ABRecord
  let singleValueChanges: [ABPropertyID: NSObject]
  let multiValueChanges: [ABPropertyID: [(NSString, NSObject)]]

  init?(oldRecord: ABRecord, newRecord: ABRecord) {
    let singleValueChanges = RecordChangeSet.findSingleValueChanges(oldRecord, newRecord)
    let multiValueChanges = RecordChangeSet.findMultiValueChanges(oldRecord, newRecord)

    if singleValueChanges.isEmpty && multiValueChanges.isEmpty {
      return nil
    }

    self.record = oldRecord
    self.singleValueChanges = singleValueChanges
    self.multiValueChanges = multiValueChanges
  }

  static let TrackedSingleValueProperties = [
    kABPersonMiddleNameProperty,
    kABPersonPrefixProperty,
    kABPersonSuffixProperty,
    kABPersonNicknameProperty,
    kABPersonOrganizationProperty,
    kABPersonJobTitleProperty,
    kABPersonDepartmentProperty
  ]

  static let TrackedMultiValueProperties = [
    kABPersonEmailProperty,
    kABPersonPhoneProperty,
    kABPersonURLProperty,
    kABPersonAddressProperty,
    kABPersonInstantMessageProperty,
    kABPersonSocialProfileProperty
  ]

  private static func findSingleValueChanges(
    oldRecord: ABRecord,
    _ newRecord: ABRecord)
    -> [ABPropertyID: NSObject]
  {
    var changes: [ABPropertyID: NSObject] = [:]

    for prop in TrackedSingleValueProperties {
      let oldVal = Records.getSingleValueProperty(prop, of: oldRecord)
      if oldVal == nil {
        let newVal = Records.getSingleValueProperty(prop, of: newRecord)
        if let nv = newVal {
          changes[prop] = nv
        }
      }
    }

    return changes
  }

  private static func findMultiValueChanges(
    oldRecord: ABRecord,
    _ newRecord: ABRecord)
    -> [ABPropertyID: [(NSString, NSObject)]]
  {
    var changes: [ABPropertyID: [(NSString, NSObject)]] = [:]

    for prop in TrackedMultiValueProperties {
      let oldMultiVals = Records.getMultiValueProperty(prop, of: oldRecord)
      let newMultiVals = Records.getMultiValueProperty(prop, of: newRecord)

      if let newMV = newMultiVals {
        let oldValues = oldMultiVals != nil ? oldMultiVals!.map { $0.1 } : []

        var changesByLabel: [(NSString, NSObject)] = []

        for newLabelAndValue in newMV {
          let (newLabel, newValue) = newLabelAndValue

          if !contains(oldValues, newValue) {
            changesByLabel.append(newLabelAndValue)
          }
        }

        if !changesByLabel.isEmpty {
          changes[prop] = changesByLabel
        }
      }
    }

    return changes
  }
}
