import UIKit

/**
 * This helper class must reside at top level with at least internal visibility.
 * Otherwise, the UITextField does not call the delegate methods.
 *
 * The name of the class is ugly, because it deserves to be so.
 */
class OnTextChangeTextFieldDelegate: NSObject, UITextFieldDelegate {
  typealias OnTextChangeCallback = (text: NSString, replacement: NSString, range: NSRange) -> Void

  private let onTextChange: OnTextChangeCallback

  init(onTextChange: OnTextChangeCallback) {
    self.onTextChange = onTextChange
  }

  func textField(
    textField: UITextField,
    shouldChangeCharactersInRange range: NSRange,
    replacementString string: NSString)
    -> Bool
  {
    onTextChange(text: textField.text, replacement: string, range: range)
    return true
  }
}
