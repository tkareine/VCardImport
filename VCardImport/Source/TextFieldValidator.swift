import UIKit

class TextFieldValidator: NSObject, UITextFieldDelegate {
  typealias Validator = String -> Bool
  typealias OnValidatedCallback = Bool -> Void

  private weak var textField: UITextField!

  private let validator: Validator
  private let onValidated: OnValidatedCallback

  private let validBorderWidth: CGFloat
  private let invalidBorderWidth: CGFloat = 2.0

  private let validBorderColor: CGColor
  private let invalidBorderColor = UIColor.redColor().CGColor

  init(
    textField: UITextField,
    validator: Validator,
    onValidated: OnValidatedCallback)
  {
    self.textField = textField
    self.validator = validator
    self.onValidated = onValidated
    validBorderWidth = textField.layer.borderWidth
    validBorderColor = textField.layer.borderColor

    super.init()

    textField.delegate = self
  }

  var isValid: Bool {
    return validator(textField.text)
  }

  func textField(
    textField: UITextField,
    shouldChangeCharactersInRange range: NSRange,
    replacementString string: NSString)
    -> Bool
  {
    let newText = changeText(textField.text, replacement: string, range: range)
    setValidationStyle(validate(newText))
    return true
  }

  func validate(affectStyle setStyle: Bool = true) -> Bool {
    let isValid = validate(textField.text)
    if setStyle {
      setValidationStyle(isValid)
    }
    return isValid
  }

  private func validate(text: NSString) -> Bool {
    let isValid = validator(text)
    onValidated(isValid)
    return isValid
  }

  private func setValidationStyle(isValid: Bool) {
    if isValid {
      textField.layer.borderWidth = validBorderWidth
      textField.layer.borderColor = validBorderColor
    } else {
      textField.layer.borderWidth = invalidBorderWidth
      textField.layer.borderColor = invalidBorderColor
    }
  }

  private func changeText(
    text: NSString,
    replacement: NSString,
    range: NSRange)
    -> NSString
  {
    let unaffectedStart = text.substringToIndex(range.location)
    let unaffectedEnd = text.substringFromIndex(range.location + range.length)
    return unaffectedStart + replacement + unaffectedEnd
  }
}
