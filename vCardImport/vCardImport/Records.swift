import Foundation
import AddressBook

struct Records {
  static func getSingleValueProperty(
    property: ABPropertyID,
    ofRecord record: ABRecord)
    -> String?
  {
    if let val = ABRecordCopyValue(record, property) {
      let str = val.takeRetainedValue() as String
      return str
    }
    return nil
  }

  static func getMultiValueProperty(
    property: ABPropertyID,
    ofRecord record: ABRecord)
    -> [(String, String)]?
  {
    if let val = ABRecordCopyValue(record, property) {
      let multiVal: ABMultiValue = val.takeRetainedValue() as ABMultiValue
      var result: [(String, String)] = []
      for i in 0..<ABMultiValueGetCount(multiVal) {
        let label = ABMultiValueCopyLabelAtIndex(multiVal, i).takeRetainedValue() as String
        let value = ABMultiValueCopyValueAtIndex(multiVal, i).takeRetainedValue() as String
        result.append((label, value))
      }
      return result
    } else {
      return nil
    }
  }

  static func setValue(
    value: AnyObject,
    toProperty property: ABPropertyID,
    ofRecord record: ABRecord)
    -> Bool
  {
    var abError: Unmanaged<CFError>?
    let didSet = ABRecordSetValue(record, property, value, &abError)
    if !didSet {
      if abError != nil {
        let err = Errors.fromCFError(abError!.takeRetainedValue())
        NSLog("Failed to set value: %@ (%d)", err.localizedDescription, err.code)
      }
      return false
    }
    return true
  }

  static func addValues(
    values: [(String, String)],
    toMultiValueProperty property: ABPropertyID,
    ofRecord record: ABRecord)
    -> Bool
  {
    let val = ABRecordCopyValue(record, property)

    var mutableMultiVal: ABMutableMultiValue
    if let v = val {
      let multiVal: ABMultiValue = val.takeRetainedValue() as ABMultiValue
      mutableMultiVal = ABMultiValueCreateMutableCopy(multiVal).takeRetainedValue() as ABMutableMultiValue
    } else {
      mutableMultiVal = ABMultiValueCreateMutable(ABPropertyType(kABMultiStringPropertyType)).takeRetainedValue() as ABMutableMultiValue
    }

    for (label, value) in values {
      let wasAdded = ABMultiValueAddValueAndLabel(mutableMultiVal, value, label, nil)

      if !wasAdded {
        NSLog("Failed to add multivalue \(label)=\(value)")
        return false
      }
    }

    return setValue(mutableMultiVal, toProperty: property, ofRecord: record)
  }
}
