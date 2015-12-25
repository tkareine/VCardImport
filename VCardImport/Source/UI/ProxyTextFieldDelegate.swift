import UIKit

class ProxyTextFieldDelegate: NSObject, UITextFieldDelegate {
  typealias OnBeginEditingCallback = UITextField -> Void
  typealias OnEndEditingCallback = UITextField -> Void
  typealias OnShouldReturnCallback = UITextField -> Bool
  typealias OnTextChangeCallback = (textField: UITextField, range: NSRange, replacement: String) -> Bool

  private var onBeginEditingCallees: [TextFieldCallee<OnBeginEditingCallback>] = []
  private var onEndEditingCallees: [TextFieldCallee<OnEndEditingCallback>] = []
  private var onShouldReturnCallees: [TextFieldCallee<OnShouldReturnCallback>] = []
  private var onTextChangeCallees: [TextFieldCallee<OnTextChangeCallback>] = []

  func addOnBeginEditing(textField: UITextField, _ callback: OnBeginEditingCallback) {
    onBeginEditingCallees.append(TextFieldCallee(textField: textField, callback: callback))
  }

  func addOnEndEditing(textField: UITextField, _ callback: OnEndEditingCallback) {
    onEndEditingCallees.append(TextFieldCallee(textField: textField, callback: callback))
  }

  func addOnShouldReturn(textField: UITextField, _ callback: OnShouldReturnCallback) {
    onShouldReturnCallees.append(TextFieldCallee(textField: textField, callback: callback))
  }

  func addOnTextChange(textField: UITextField, _ callback: OnTextChangeCallback) {
    onTextChangeCallees.append(TextFieldCallee(textField: textField, callback: callback))
  }

  func removeOnBeginEditing(textField: UITextField) {
    removeCallee(with: textField, from: onBeginEditingCallees)
  }

  func removeOnEndEditing(textField: UITextField) {
    removeCallee(with: textField, from: onEndEditingCallees)
  }

  func removeOnShouldReturn(textField: UITextField) {
    removeCallee(with: textField, from: onShouldReturnCallees)
  }

  func removeOnTextChange(textField: UITextField) {
    removeCallee(with: textField, from: onTextChangeCallees)
  }

  // MARK: UITextFieldDelegate Methods

  func textFieldDidBeginEditing(textField: UITextField) {
    if let callee = findCallee(with: textField, from: onBeginEditingCallees) {
      callee.callback(textField)
    }
  }

  func textFieldDidEndEditing(textField: UITextField) {
    if let callee = findCallee(with: textField, from: onEndEditingCallees) {
      callee.callback(textField)
    }
  }

  func textFieldShouldReturn(textField: UITextField) -> Bool {
    if let callee = findCallee(with: textField, from: onShouldReturnCallees) {
      return callee.callback(textField)
    } else {
      return false
    }
  }

  func textField(
    textField: UITextField,
    shouldChangeCharactersInRange range: NSRange,
    replacementString string: String)
    -> Bool
  {
    if let callee = findCallee(with: textField, from: onTextChangeCallees) {
      return callee.callback(textField: textField, range: range, replacement: string)
    } else {
      return true
    }
  }

  // MARK: Helpers

  private func findCallee<T>(
    with textField: UITextField,
    from callees: [TextFieldCallee<T>])
    -> TextFieldCallee<T>?
  {
    return callees.findElementWhere { $0.textField === textField }
  }

  private func removeCallee<T>(
    with textField: UITextField,
    var from callees: [TextFieldCallee<T>])
  {
    if let index = callees.findIndexWhere({ $0.textField === textField }) {
      callees.removeAtIndex(index)
    }
  }
}

private struct TextFieldCallee<T> {
  let textField: UITextField
  let callback: T
}
