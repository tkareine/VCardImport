import AddressBook

struct RecordChangeSet {
  let record: ABRecord
  let singleValueChanges: [ABPropertyID: String]
  let multiValueChanges: [ABPropertyID: [(String, String)]]

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
    kABPersonJobTitleProperty,
    kABPersonDepartmentProperty,
    kABPersonOrganizationProperty
  ]

  static let TrackedMultiValueProperties = [
    kABPersonEmailProperty,
    kABPersonPhoneProperty,
    kABPersonURLProperty,
  ]

  private static func findSingleValueChanges(
    oldRecord: ABRecord,
    _ newRecord: ABRecord)
    -> [ABPropertyID: String]
  {
    var changes: [ABPropertyID: String] = [:]

    for prop in TrackedSingleValueProperties {
      let oldVal = Records.getSingleValueProperty(prop, ofRecord: oldRecord)
      if oldVal == nil {
        let newVal = Records.getSingleValueProperty(prop, ofRecord: newRecord)
        if let nv = newVal {
          changes[prop] = newVal
        }
      }
    }

    return changes
  }

  private static func findMultiValueChanges(
    oldRecord: ABRecord,
    _ newRecord: ABRecord)
    -> [ABPropertyID: [(String, String)]]
  {
    var changes: [ABPropertyID: [(String, String)]] = [:]

    for prop in TrackedMultiValueProperties {
      let oldMultiVals = Records.getMultiValueProperty(prop, ofRecord: oldRecord)
      let newMultiVals = Records.getMultiValueProperty(prop, ofRecord: newRecord)

      if let newMV = newMultiVals {
        let oldValues = oldMultiVals != nil ? oldMultiVals!.map { $0.1 } : []

        var changesByLabel: [(String, String)] = []

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
