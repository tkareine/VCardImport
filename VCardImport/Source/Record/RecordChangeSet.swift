import Foundation
import AddressBook

struct RecordChangeSet {
  let record: ABRecord
  let singleValueChanges: [ABPropertyID: AnyObject]
  let multiValueChanges: [ABPropertyID: [(String, AnyObject)]]
  let imageChange: NSData?

  init?(oldRecord: ABRecord, newRecord: ABRecord, trackPersonNickName: Bool) {
    let singleValueChanges = RecordChangeSet.findSingleValueChanges(
      oldRecord: oldRecord,
      newRecord: newRecord,
      trackPersonNickName: trackPersonNickName)
    let multiValueChanges = RecordChangeSet.findMultiValueChanges(oldRecord, newRecord)
    let imageChange = RecordChangeSet.findImageChange(oldRecord, newRecord)

    if singleValueChanges.isEmpty && multiValueChanges.isEmpty && imageChange == nil {
      return nil
    }

    self.record = oldRecord
    self.singleValueChanges = singleValueChanges
    self.multiValueChanges = multiValueChanges
    self.imageChange = imageChange
  }

  static let TrackedSingleValueProperties = [
    kABPersonMiddleNameProperty,
    kABPersonPrefixProperty,
    kABPersonSuffixProperty,
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
    oldRecord oldRecord: ABRecord,
    newRecord: ABRecord,
    trackPersonNickName: Bool)
    -> [ABPropertyID: AnyObject]
  {
    var changes: [ABPropertyID: AnyObject] = [:]

    let trackedProperties = trackPersonNickName
      ? [kABPersonNicknameProperty] + TrackedSingleValueProperties
      : TrackedSingleValueProperties

    for prop in trackedProperties {
      let oldVal: AnyObject? = Records.getSingleValueProperty(prop, of: oldRecord)
      if oldVal == nil {
        if let newVal: AnyObject = Records.getSingleValueProperty(prop, of: newRecord) {
          changes[prop] = newVal
        }
      }
    }

    return changes
  }

  private static func findMultiValueChanges(
    oldRecord: ABRecord,
    _ newRecord: ABRecord)
    -> [ABPropertyID: [(String, AnyObject)]]
  {
    var changes: [ABPropertyID: [(String, AnyObject)]] = [:]

    for prop in TrackedMultiValueProperties {
      let oldValues: NSArray = Records.getMultiValueProperty(prop, of: oldRecord).map { $0.1 }
      let newMultiVals = Records.getMultiValueProperty(prop, of: newRecord)

      var changesByLabel: [(String, AnyObject)] = []

      for newLabelAndValue in newMultiVals {
        let (_, newValue) = newLabelAndValue

        if !oldValues.containsObject(newValue) {
          changesByLabel.append(newLabelAndValue)
        }
      }

      if !changesByLabel.isEmpty {
        changes[prop] = changesByLabel
      }
    }

    return changes
  }

  private static func findImageChange(
    oldRecord: ABRecord,
    _ newRecord: ABRecord)
    -> NSData?
  {
    if Records.hasImage(oldRecord) {
      return nil
    }
    return Records.getImage(newRecord)
  }
}
