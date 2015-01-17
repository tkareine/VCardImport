import UIKit

class VCardSourceDetailViewController: UIViewController {
  @IBOutlet weak var nameField: UITextField!
  @IBOutlet weak var urlField: UITextField!
  @IBOutlet weak var urlValidationLabel: UILabel!
  @IBOutlet weak var isValidatingURLIndicator: UIActivityIndicatorView!
  @IBOutlet weak var isEnabledLabel: UILabel!
  @IBOutlet weak var isEnabledSwitch: UISwitch!

  private let source: VCardSource
  private let isNewSource: Bool
  private let urlConnection: URLConnection
  private let doneCallback: VCardSource -> Void

  private var shouldCallDoneCallbackOnViewDisappear: Bool
  private var nameFieldValidator: TextFieldValidator<Bool>!
  private var urlFieldValidator: TextFieldValidator<Bool>!

  // MARK: Controller Life Cycle

  init(
    source: VCardSource,
    isNewSource: Bool,
    urlConnection: URLConnection,
    doneCallback: VCardSource -> Void)
  {
    self.source = source
    self.isNewSource = isNewSource
    self.urlConnection = urlConnection
    self.doneCallback = doneCallback

    shouldCallDoneCallbackOnViewDisappear = !isNewSource

    super.init(nibName: "VCardSourceDetailViewController", bundle: nil)

    if isNewSource {
      navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancel:")
      navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "done:")
    }
  }

  required init(coder decoder: NSCoder) {
    fatalError("not implemented")
  }

  // MARK: View Life Cycle

  override func viewWillAppear(animated: Bool) {
    super.viewWillDisappear(animated)

    nameFieldValidator = TextFieldValidator(
      textField: nameField,
      syncValidator: { !$0.isEmpty ? .Success(true) : .Failure("empty") },
      onValidated: { [weak self] _ in
        if let s = self {
          s.refreshDoneButtonState()
        }
      })

    urlFieldValidator = TextFieldValidator(
      textField: urlField,
      asyncValidator: { [weak self] url in
        if let s = self {
          s.beginURLValidation()
          return s.checkIsReachable(url)
        } else {
          return Future.failed("view disappeared")
        }
      },
      onValidated: { [weak self] result in
        if let s = self {
          s.endURLValidation(result)
          s.refreshDoneButtonState()
        }
      })

    nameField.text = source.name
    urlField.text = source.connection.url.absoluteString
    isEnabledSwitch.on = source.isEnabled
    urlValidationLabel.alpha = 0

    if isNewSource {
      isEnabledLabel.hidden = true
      isEnabledSwitch.hidden = true
      refreshDoneButtonState()
    } else {
      nameFieldValidator.validate(affectStyle: true)
      urlFieldValidator.validate(affectStyle: true)
    }
  }

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)

    if shouldCallDoneCallbackOnViewDisappear {
      let urlCandidate = NSURL(string: urlField.text)
      let newURL = urlCandidate != nil ? urlCandidate! : source.connection.url

      let newSource = source.with(
        name: nameField.text,
        connection: VCardSource.Connection(url: newURL),
        isEnabled: isEnabledSwitch.on
      )

      doneCallback(newSource)
    }
  }

  // MARK: Actions

  func cancel(sender: AnyObject) {
    presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
  }

  func done(sender: AnyObject) {
    shouldCallDoneCallbackOnViewDisappear = true
    presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
  }

  // MARK: Helpers

  private func refreshDoneButtonState() {
    if let button = navigationItem.rightBarButtonItem {
      switch (nameFieldValidator.lastResult, urlFieldValidator.lastResult) {
      case (.Some(.Success), .Some(.Success)):
        button.enabled = true
      default:
        button.enabled = false
      }
    }
  }

  private func beginURLValidation() {
    urlValidationLabel.text = "Validating URL…"

    UIView.animateWithDuration(
      0.5,
      delay: 0,
      options: .CurveEaseIn,
      animations: {
        self.urlValidationLabel.alpha = 1
      },
      completion: nil)

    isValidatingURLIndicator.startAnimating()
  }

  private func endURLValidation(result: Try<Bool>) {
    switch result {
    case .Success:
      urlValidationLabel.text = "URL is valid"
      UIView.animateWithDuration(
        0.5,
        delay: 0.5,
        options: .CurveEaseOut,
        animations: {
          self.urlValidationLabel.alpha = 0
        },
        completion: nil)
    case .Failure(let desc):
      urlValidationLabel.text = desc
    }

    isValidatingURLIndicator.stopAnimating()
  }

  private func checkIsReachable(urlString: String) -> Future<Bool> {
    if let url = NSURL(string: urlString) {
      if url.isValidHTTPURL {
        return self.urlConnection
          .head(url, headers: Config.Net.VCardHTTPHeaders)
          .map { _ in true }
      }
    }
    return Future.failed("Invalid URL")
  }
}
