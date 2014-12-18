import AddressBook

struct RecordChangeSet {
  let record: ABRecord
  let multiValueChanges: [ABPropertyID: [(String, String)]]

  static let MultiValuePropertiesToCheck = [
    kABPersonEmailProperty,
    kABPersonPhoneProperty,
    kABPersonURLProperty,
  ]

  static func resolve(
    name: String,
    oldRecord: ABRecord,
    newRecord: ABRecord)
    -> RecordChangeSet?
  {
    var multiValueChanges: [ABPropertyID: [(String, String)]] = [:]

    for prop in MultiValuePropertiesToCheck {
      let oldMV = Records.getMultiValueProperty(prop, ofRecord: oldRecord)
      let newMV = Records.getMultiValueProperty(prop, ofRecord: newRecord)

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
      : RecordChangeSet(record: oldRecord, multiValueChanges: multiValueChanges)
  }
}
