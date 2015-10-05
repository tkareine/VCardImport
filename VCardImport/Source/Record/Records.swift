import Foundation
import AddressBook

struct Records {
  static func hasImage(record: ABRecord) -> Bool {
    return ABPersonHasImageData(record)
  }

  static func getSingleValueProperty(
    property: ABPropertyID,
    of record: ABRecord)
    -> AnyObject?
  {
    if let val = ABRecordCopyValue(record, property) {
      return val.takeRetainedValue()
    } else {
      return nil
    }
  }

  static func getMultiValueProperty(
    property: ABPropertyID,
    of record: ABRecord)
    -> [(String, AnyObject)]
  {
    if let val = ABRecordCopyValue(record, property) {
      let multiVal: ABMultiValue = val.takeRetainedValue() as ABMultiValue
      var result: [(String, AnyObject)] = []
      for i in 0..<ABMultiValueGetCount(multiVal) {
        if let labelPtr = ABMultiValueCopyLabelAtIndex(multiVal, i) {
          let label = labelPtr.takeRetainedValue() as String
          if let valuePtr = ABMultiValueCopyValueAtIndex(multiVal, i) {
            let value: AnyObject = valuePtr.takeRetainedValue()
            result.append((label, value))
          }
        }
      }
      return result
    } else {
      return []
    }
  }

  static func getImage(record: ABRecord) -> NSData? {
    if let img = ABPersonCopyImageData(record) {
      return (img.takeRetainedValue() as NSData)
    } else {
      return nil
    }
  }

  static func setValue(
    value: AnyObject,
    toSingleValueProperty property: ABPropertyID,
    of record: ABRecord)
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

  static func addValues<T: AnyObject>(
    values: [(String, T)],
    toMultiValueProperty property: ABPropertyID,
    of record: ABRecord)
    -> Bool
  {
    let val = ABRecordCopyValue(record, property)

    let mutableMultiVal: ABMutableMultiValue
    if let v = val {
      let multiVal: ABMultiValue = v.takeRetainedValue()
      mutableMultiVal = ABMultiValueCreateMutableCopy(multiVal).takeRetainedValue()
    } else {
      mutableMultiVal = ABMultiValueCreateMutable(ABPropertyType(kABMultiStringPropertyType)).takeRetainedValue()
    }

    for (label, value) in values {
      let wasAdded = ABMultiValueAddValueAndLabel(mutableMultiVal, value, label, nil)

      if !wasAdded {
        NSLog("Failed to add multivalue \(label)=\(value)")
        return false
      }
    }

    return setValue(mutableMultiVal, toSingleValueProperty: property, of: record)
  }

  static func setImage(imageData: NSData, of record: ABRecord) -> Bool {
    var abError: Unmanaged<CFError>?
    let didSet = ABPersonSetImageData(record, imageData, &abError)
    if !didSet {
      if abError != nil {
        let err = Errors.fromCFError(abError!.takeRetainedValue())
        NSLog("Failed to set image: %@ (%d)", err.localizedDescription, err.code)
      }
      return false
    }
    return true
  }
}
