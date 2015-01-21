import UIKit

class VCardSourceDetailViewOwner: NSObject {
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var nameField: UITextField!
  @IBOutlet weak var urlLabel: UILabel!
  @IBOutlet weak var urlField: UITextField!
  @IBOutlet weak var urlValidationLabel: UILabel!
  @IBOutlet weak var isValidatingURLIndicator: UIActivityIndicatorView!
  @IBOutlet weak var usernameLabel: UILabel!
  @IBOutlet weak var usernameField: UITextField!
  @IBOutlet weak var passwordLabel: UILabel!
  @IBOutlet weak var passwordField: UITextField!
  @IBOutlet weak var isEnabledLabel: UILabel!
  @IBOutlet weak var isEnabledSwitch: UISwitch!

  var view: UIView!

  // MARK: View Life Cycle

  override init() {
    super.init()

    NSNotificationCenter.defaultCenter().addObserver(
      self,
      selector: "resetFontSizes",
      name: UIContentSizeCategoryDidChangeNotification,
      object: nil)
  }

  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }

  // MARK: Public API

  func loadView(#source: VCardSource, isNewSource isNew: Bool) -> UIView {
    view = NSBundle
      .mainBundle()
      .loadNibNamed("VCardSourceDetailView", owner: self, options: nil).first! as UIView

    view.setTranslatesAutoresizingMaskIntoConstraints(false)

    setupSubviews(source: source, isNewSource: isNew)
    resetFontSizes()

    return view
  }

  // MARK: Actions

  @IBAction func backgroundTapped(sender: AnyObject) {
    view.endEditing(true)
  }

  // MARK: Helpers

  func beginURLValidationProgress() {
    urlValidationLabel.text = "Validating URL…"

    UIView.animateWithDuration(
      Config.UI.AnimationDurationFadeMessage,
      delay: 0,
      options: .CurveEaseIn | .BeginFromCurrentState,
      animations: {
        self.urlValidationLabel.alpha = 1
      },
      completion: nil)

    isValidatingURLIndicator.startAnimating()
  }

  func endURLValidationProgress(result: Try<NSURL>) {
    switch result {
    case .Success:
      urlValidationLabel.text = "URL is valid"
      UIView.animateWithDuration(
        Config.UI.AnimationDurationFadeMessage,
        delay: Config.UI.AnimationDelayFadeOutMessage,
        options: .CurveEaseOut | .BeginFromCurrentState,
        animations: {
          self.urlValidationLabel.alpha = 0
        },
        completion: nil)
    case .Failure(let desc):
      urlValidationLabel.text = desc
    }

    isValidatingURLIndicator.stopAnimating()
  }

  func resetFontSizes() {
    let bodyFont = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
    nameLabel.font = bodyFont
    nameField.font = bodyFont
    urlLabel.font = bodyFont
    urlField.font = bodyFont
    urlValidationLabel.font = UIFont.systemFontOfSize(bodyFont.pointSize - 2)
    usernameLabel.font = bodyFont
    usernameField.font = bodyFont
    passwordLabel.font = bodyFont
    passwordField.font = bodyFont
    isEnabledLabel.font = bodyFont
  }

  private func setupSubviews(#source: VCardSource, isNewSource isNew: Bool) {
    nameField.text = source.name
    urlField.text = source.connection.url.absoluteString
    isEnabledSwitch.on = source.isEnabled
    urlValidationLabel.alpha = 0
    isValidatingURLIndicator.hidesWhenStopped = true

    if isNew {
      isEnabledLabel.hidden = true
      isEnabledSwitch.hidden = true
    }
  }
}
