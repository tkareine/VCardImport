import UIKit

// TODO: Implement throttling so that only the most recent event is waiting for
// the queue
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

  private var lastValidationResult: Try<T>?
  private var delegate: OnTextChangeTextFieldDelegate!
  private weak var textField: UITextField!

  init(
    textField: UITextField,
    asyncValidator: AsyncValidator,
    onValidated: OnValidatedCallback)
  {
    self.textField = textField
    self.validator = asyncValidator
    self.onValidated = onValidated

    validBorderWidth = textField.layer.borderWidth
    validBorderColor = textField.layer.borderColor

    delegate = OnTextChangeTextFieldDelegate() { text, replacement, range in
      QueueExecution.async(self.queue) {
        let newText = self.change(text: text, replacement: replacement, range: range)
        let result = self.validate(newText)
        self.setValidationStyle(result)
      }
    }

    textField.delegate = delegate
  }

  convenience init(
    textField: UITextField,
    syncValidator: SyncValidator,
    onValidated: OnValidatedCallback)
  {
    self.init(
      textField: textField,
      asyncValidator: { Future.fromTry(syncValidator($0)) },
      onValidated: onValidated)
  }

  var lastResult: Try<T>? {
    var result: Try<T>?
    QueueExecution.sync(queue) { result = self.lastValidationResult }
    return result
  }

  func validate(affectStyle setStyle: Bool = true) {
    let text = textField.text
    QueueExecution.async(queue) {
      let result = self.validate(text)
      if setStyle {
        self.setValidationStyle(result)
      }
    }
  }

  private func validate(text: NSString) -> Try<T> {
    let result = validator(text).get()
    lastValidationResult = result
    QueueExecution.async(QueueExecution.mainQueue) { self.onValidated(result) }
    return result
  }

  private func setValidationStyle(result: Try<T>) {
    QueueExecution.async(QueueExecution.mainQueue) {
      if let field = self.textField {
        switch result {
        case .Success:
          field.layer.borderWidth = self.validBorderWidth
          field.layer.borderColor = self.validBorderColor
        case .Failure:
          field.layer.borderWidth = Config.UI.ValidationBorderWidth
          field.layer.borderColor = Config.UI.ValidationBorderColor
        }
        field.layer.cornerRadius = Config.UI.ValidationCornerRadius
      }
    }
  }

  private func change(
    #text: NSString,
    replacement: NSString,
    range: NSRange)
    -> NSString
  {
    let unaffectedStart = text.substringToIndex(range.location)
    let unaffectedEnd = text.substringFromIndex(range.location + range.length)
    return unaffectedStart + replacement + unaffectedEnd
  }
}
