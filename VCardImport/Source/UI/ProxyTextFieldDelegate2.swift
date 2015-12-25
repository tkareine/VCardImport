import UIKit

class ProxyTextFieldDelegate2: NSObject, UITextFieldDelegate {
  private let onBeginEditing: UITextField -> Void
  private let onEndEditing: UITextField -> Void
  private let onShouldReturn: UITextField -> Bool

  init(
    beginEditingHandler onBeginEditing: UITextField -> Void,
    endEditingHandler onEndEditing: UITextField -> Void,
    shouldReturnHandler onShouldReturn: UITextField -> Bool)
  {
    self.onBeginEditing = onBeginEditing
    self.onEndEditing = onEndEditing
    self.onShouldReturn = onShouldReturn
  }

  // MARK: UITextFieldDelegate

  func textFieldDidBeginEditing(textField: UITextField) {
    onBeginEditing(textField)
  }

  func textFieldDidEndEditing(textField: UITextField) {
    onEndEditing(textField)
  }

  func textFieldShouldReturn(textField: UITextField) -> Bool {
    return onShouldReturn(textField)
  }
}
