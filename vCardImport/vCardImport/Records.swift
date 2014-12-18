import Foundation
import AddressBook

struct Records {
  static func getSingleValueProperty(
    property: ABPropertyID,
    ofRecord record: ABRecord)
    -> String
  {
    return ABRecordCopyValue(record, property).takeRetainedValue() as String
  }

  static func getMultiValueProperty(
    property: ABPropertyID,
    ofRecord record: ABRecord)
    -> [(String, String)]
  {
    let multiVal: ABMultiValue = ABRecordCopyValue(record, property).takeRetainedValue() as ABMultiValue
    var result: [(String, String)] = []
    for i in 0..<ABMultiValueGetCount(multiVal) {
      let label = ABMultiValueCopyLabelAtIndex(multiVal, i).takeRetainedValue() as String
      let value = ABMultiValueCopyValueAtIndex(multiVal, i).takeRetainedValue() as String
      result.append((label, value))
    }
    return result
  }

  static func addValues(
    values: [(String, String)],
    toMultiValueProperty property: ABPropertyID,
    ofRecord record: ABRecord)
    -> Bool
  {
    let multiVal: ABMultiValue = ABRecordCopyValue(record, property).takeRetainedValue() as ABMultiValue
    let mutableMultiVal: ABMutableMultiValue = ABMultiValueCreateMutableCopy(multiVal).takeRetainedValue() as ABMutableMultiValue
    for (label, value) in values {
      let wasAdded = ABMultiValueAddValueAndLabel(mutableMultiVal, value, label, nil)

      if !wasAdded {
        NSLog("Failed to add multivalue \(label)=\(value)")
        return false
      }
    }

    var abError: Unmanaged<CFError>?
    let didSet = ABRecordSetValue(record, property, mutableMultiVal, &abError)

    if !didSet {
      if abError != nil {
        let err = Errors.fromCFError(abError!.takeRetainedValue())
        NSLog("Failed to set multivalue: %@ (%d)", err.localizedDescription, err.code)
      }
      return false
    }

    return true
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
    }
    return true
  }
}
