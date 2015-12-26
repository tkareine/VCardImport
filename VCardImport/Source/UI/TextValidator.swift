import MiniFuture

class TextValidator {
  private var validationDebouncer: (String -> Void)!
  private var isLastValidationSuccess: Bool?

  init(
    asyncValidation textValidator: String -> Future<String>,
    validationCompletion onValidated: Try<String> -> Void,
    queueTo onValidatedQueue: QueueExecution.Queue = QueueExecution.mainQueue)
  {
    let queue = QueueExecution.makeSerialQueue("InputValidator")
    let switcher = Future<String>.makeSwitchLatest()

    validationDebouncer = QueueExecution.makeDebouncer(Config.UI.ValidationThrottleInMS, queue) { [weak self] text in
      // validator still exists, makes sense to validate?
      if self != nil {
        // never call Future#get here as switcher completes only the latest Future
        switcher(textValidator(text)).onComplete { result in
          // validator still exists, makes sense to pass validation result?
          if let s = self {
            s.isLastValidationSuccess = result.isSuccess
            QueueExecution.async(onValidatedQueue) { onValidated(result) }
          }
        }
      }
    }
  }

  convenience init(
    syncValidation textValidator: String -> Try<String>,
    validationCompletion onValidated: Try<String> -> Void,
    queueTo onValidatedQueue: QueueExecution.Queue = QueueExecution.mainQueue)
  {
    self.init(
      asyncValidation: { Future.fromTry(textValidator($0)) },
      validationCompletion: onValidated,
      queueTo: onValidatedQueue)
  }

  var isValid: Bool? {
    return isLastValidationSuccess
  }

  func validate(text: String) {
    validationDebouncer(text)
  }
}
