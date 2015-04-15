import UIKit
import MiniFuture

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

  private weak var textField: UITextField?
  private weak var textFieldDelegate: ProxyTextFieldDelegate?

  private let switcher = Future<T>.makeSwitchLatest()
  private var validationDebouncer: (String -> Void)!

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

    validationDebouncer = QueueExecution.makeDebouncer(Config.UI.ValidationThrottleInMS, queue) { [weak self] in
      if let s = self {  // view might have been destroyed already
        s.validate($0)
      }
    }

    self.textFieldDelegate?.addOnTextChange(textField) { tf, range, replacement in
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
      if let dl = textFieldDelegate {
        dl.removeOnTextChange(tf)
      }
    }
  }

  func validate() {
    if let tf = textField {
      let text = tf.text
      QueueExecution.async(queue) { self.validationDebouncer(text) }
    }
  }

  private func validate(text: String) {
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
    #text: String,
    range: NSRange,
    replacement: String)
    -> String
  {
    let unaffectedStart = (text as NSString).substringToIndex(range.location)
    let unaffectedEnd = (text as NSString).substringFromIndex(range.location + range.length)
    return unaffectedStart + replacement + unaffectedEnd
  }
}
