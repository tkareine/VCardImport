import UIKit

class VCardSourceDetailViewOwner: NSObject {
  @IBOutlet weak var topConstraint: NSLayoutConstraint!
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

  private let textFieldDelegate: ProxyTextFieldDelegate

  private var focusedTextField: UITextField!

  private var originalScrollViewContentInsets = UIEdgeInsetsZero
  private var originalScrollViewScrollIndicatorInsets = UIEdgeInsetsZero
  private var originalContainerViewFrame = CGRect()

  private weak var containerView: UIView!
  private weak var scrollView: UIScrollView!
  private weak var navigationController: UINavigationController?

  // MARK: View Life Cycle

  init(textFieldDelegate: ProxyTextFieldDelegate) {
    self.textFieldDelegate = textFieldDelegate

    super.init()

    NSNotificationCenter.defaultCenter().addObserver(
      self,
      selector: "resetFontSizes",
      name: UIContentSizeCategoryDidChangeNotification,
      object: nil)
  }

  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)

    for f in [nameField, urlField, usernameField, passwordField] {
      textFieldDelegate.removeOnBeginEditing(f)
      textFieldDelegate.removeOnEndEditing(f)
      textFieldDelegate.removeOnShouldReturn(f)
    }
  }

  // MARK: Public API

  func loadView(#source: VCardSource, isNewSource isNew: Bool) -> UIView {
    view = NSBundle
      .mainBundle()
      .loadNibNamed("VCardSourceDetailView", owner: self, options: nil).first! as UIView

    view.setTranslatesAutoresizingMaskIntoConstraints(false)

    setupSubviews(source: source, isNewSource: isNew)
    resetFontSizes()
    setupTextFieldDelegate()

    return view
  }

  func setScrollingToFocusedTextField(
    #containerView: UIView,
    scrollView: UIScrollView,
    navigationController: UINavigationController?)
  {
    self.containerView = containerView
    self.scrollView = scrollView
    self.navigationController = navigationController

    NSNotificationCenter.defaultCenter().addObserver(
      self,
      selector: "keyboardDidShow:",
      name: UIKeyboardDidShowNotification,
      object: nil)

    NSNotificationCenter.defaultCenter().addObserver(
      self,
      selector: "keyboardWillHide:",
      name: UIKeyboardWillHideNotification,
      object: nil)
  }

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

  // MARK: Actions

  @IBAction func backgroundTapped(sender: AnyObject) {
    view.endEditing(true)
  }

  // MARK: Notification Handlers

  func keyboardDidShow(notification: NSNotification) {
    // from http://spin.atomicobject.com/2014/03/05/uiscrollview-autolayout-ios/

    if containerView == nil || scrollView == nil || focusedTextField == nil {
      return
    }

    func topOffset() -> CGFloat {
      if let nv = navigationController {
        return nv.toolbar.frame.size.height + topConstraint.constant
      } else {
        return 0
      }
    }

    func bottomOffset(info: [NSObject: AnyObject]) -> CGFloat {
      let nsvalue = info[UIKeyboardFrameBeginUserInfoKey]! as NSValue
      let orgRect = nsvalue.CGRectValue()
      let convRect = containerView.convertRect(orgRect, fromView: nil)
      return convRect.size.height
    }

    if let info = notification.userInfo {
      let top = topOffset()
      let bottom = bottomOffset(info)

      let contentInsets = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)

      originalScrollViewContentInsets = scrollView.contentInset
      originalScrollViewScrollIndicatorInsets = scrollView.scrollIndicatorInsets

      scrollView.contentInset = contentInsets
      scrollView.scrollIndicatorInsets = contentInsets

      originalContainerViewFrame = containerView.frame

      containerView.frame = CGRect(
        x: originalContainerViewFrame.origin.x,
        y: originalContainerViewFrame.origin.y,
        width: originalContainerViewFrame.size.width,
        height: originalContainerViewFrame.size.height - bottom)

//      NSLog("-------------")
//      NSLog("top=\(top), bottom=\(bottom)")
//      NSLog("containerView.frame=\(containerView.frame)")
//      NSLog("original containerView.frame=\(originalContainerViewFrame)")

      if !CGRectContainsPoint(containerView.frame, focusedTextField.frame.origin) {
        scrollView.scrollRectToVisible(focusedTextField.frame, animated: true)
      }
    }
  }

  func keyboardWillHide(notification: NSNotification) {
    if containerView == nil || scrollView == nil {
      return
    }

    containerView.frame = originalContainerViewFrame
    scrollView.contentInset = originalScrollViewContentInsets
    scrollView.scrollIndicatorInsets = originalScrollViewScrollIndicatorInsets
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

  // MARK: Helpers

  private func setupSubviews(#source: VCardSource, isNewSource isNew: Bool) {
    nameField.text = source.name
    urlField.text = source.connection.url
    isEnabledSwitch.on = source.isEnabled
    urlValidationLabel.alpha = 0
    isValidatingURLIndicator.hidesWhenStopped = true
    usernameField.text = source.connection.username
    passwordField.text = source.connection.password

    if isNew {
      isEnabledLabel.hidden = true
      isEnabledSwitch.hidden = true
    }
  }

  private func setupTextFieldDelegate() {
    nameField.delegate = textFieldDelegate
    urlField.delegate = textFieldDelegate
    usernameField.delegate = textFieldDelegate
    passwordField.delegate = textFieldDelegate

    let fields = [nameField, urlField, usernameField, passwordField]

    for f in fields {
      textFieldDelegate.addOnBeginEditing(f) { tf in
        self.focusedTextField = tf
      }

      textFieldDelegate.addOnEndEditing(f) { tf in
        self.focusedTextField = nil
      }

      textFieldDelegate.addOnShouldReturn(f) { tf in
        tf.resignFirstResponder()
        return true
      }
    }
  }
}
