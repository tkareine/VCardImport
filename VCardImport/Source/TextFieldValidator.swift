import UIKit

class TextFieldValidator<T> {
  typealias SyncValidator = String -> Try<T>
  typealias AsyncValidator = String -> Future<T>
  typealias OnValidatedCallback = Try<T> -> Void

  private let validator: AsyncValidator
  private let onValidated: OnValidatedCallback

  private let queue = dispatch_queue_create(
    Config.BundleIdentifier + ".TextFieldValidator",
    DISPATCH_QUEUE_SERIAL)

  private let validBorderWidth: CGFloat
  private let validBorderColor: CGColor

  private weak var textField: UITextField!

  private let switcher: (Future<T> -> Future<T>) = QueueExecution.makeSwitchLatest()
  private let validationDebouncer: (String -> Void)!
  private let textFieldDelegate: ProxyTextFieldDelegate

  init(
    textField: UITextField,
    textFieldDelegate: ProxyTextFieldDelegate,
    asyncValidator: AsyncValidator,
    onValidated: OnValidatedCallback)
  {
    self.textField = textField
    self.validator = asyncValidator
    self.onValidated = onValidated
    self.textFieldDelegate = textFieldDelegate

    validBorderWidth = textField.layer.borderWidth
    validBorderColor = textField.layer.borderColor

    validationDebouncer = QueueExecution.makeDebouncer(Config.UI.ValidationThrottleInMS, queue) {
      self.validate($0)
    }

    textFieldDelegate.addOnTextChange(textField) { tf, range, replacement in
      let oldText = tf.text
      QueueExecution.async(self.queue) {
        let newText = self.change(text: oldText, range: range, replacement: replacement)
        self.validationDebouncer(newText)
      }
      return true
    }
  }

  convenience init(
    textField: UITextField,
    textFieldDelegate: ProxyTextFieldDelegate,
    syncValidator: SyncValidator,
    onValidated: OnValidatedCallback)
  {
    self.init(
      textField: textField,
      textFieldDelegate: textFieldDelegate,
      asyncValidator: { Future.fromTry(syncValidator($0)) },
      onValidated: onValidated)
  }

  deinit {
    if let tf = textField {
      textFieldDelegate.removeOnTextChange(tf)
    }
  }

  func validate() {
    let text = textField.text
    QueueExecution.async(queue) { self.validationDebouncer(text) }
  }

  private func validate(text: NSString) {
    // never call Future#get here as switcher completes only the latest Future
    switcher(validator(text)).onComplete { result in
      QueueExecution.async(QueueExecution.mainQueue) {
        self.setValidationStyle(result)
        self.onValidated(result)
      }
    }
  }

  private func setValidationStyle(result: Try<T>) {
    if let field = textField {
      switch result {
      case .Success:
        field.layer.borderWidth = validBorderWidth
        field.layer.borderColor = validBorderColor
      case .Failure:
        field.layer.borderWidth = Config.UI.ValidationBorderWidth
        field.layer.borderColor = Config.UI.ValidationBorderColor
      }
      field.layer.cornerRadius = Config.UI.ValidationCornerRadius
    }
  }

  private func change(
    #text: NSString,
    range: NSRange,
    replacement: NSString)
    -> NSString
  {
    let unaffectedStart = text.substringToIndex(range.location)
    let unaffectedEnd = text.substringFromIndex(range.location + range.length)
    return unaffectedStart + replacement + unaffectedEnd
  }
}
