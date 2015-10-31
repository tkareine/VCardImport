import UIKit
import MiniFuture

class VCardSourceDetailViewController: UIViewController {
  @IBOutlet weak var noticeLabel: UILabel!
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

  private let source: VCardSource
  private let isNewSource: Bool
  private let httpRequests: HTTPRequestable
  private let doneCallback: VCardSource -> Void
  private let textFieldDelegate: ProxyTextFieldDelegate

  private var shouldCallDoneCallbackOnViewDisappear: Bool
  private var nameFieldValidator: TextFieldValidator<String>!
  private var urlFieldValidator: TextFieldValidator<NSURL>!

  private var isValidCurrentName = false
  private var isValidCurrentURL = false

  private var scrollView: UIScrollView!
  private var contentView: UIView!
  private var focusedTextField: UITextField!

  // MARK: Controller Life Cycle

  init(
    source: VCardSource,
    isNewSource: Bool,
    httpRequestsWith httpRequests: HTTPRequestable,
    doneCallback: VCardSource -> Void)
  {
    self.source = source
    self.isNewSource = isNewSource
    self.httpRequests = httpRequests
    self.doneCallback = doneCallback
    textFieldDelegate = ProxyTextFieldDelegate()

    shouldCallDoneCallbackOnViewDisappear = !isNewSource

    super.init(nibName: nil, bundle: nil)

    if isNewSource {
      navigationItem.title = "Add vCard Source"
      navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancel:")
      navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "done:")
    }
  }

  required init?(coder decoder: NSCoder) {
    fatalError("not implemented")
  }

  // MARK: View Life Cycle

  override func loadView() {
    func makeScrollView() -> UIScrollView {
      let sv = UIScrollView()
      sv.backgroundColor = UIColor.whiteColor()
      return sv
    }

    func makeContentView() -> UIView {
      return NSBundle
        .mainBundle()
        .loadNibNamed("VCardSourceDetailView", owner: self, options: nil).first! as! UIView
    }

    scrollView = makeScrollView()
    contentView = makeContentView()
    scrollView.addSubview(contentView)

    view = scrollView
  }

  override func viewDidLoad() {
    func setupSubviews() {
      nameField.text = source.name
      urlField.text = source.connection.url
      isEnabledSwitch.on = source.isEnabled
      urlValidationLabel.alpha = 0
      isValidatingURLIndicator.hidesWhenStopped = true
      usernameField.text = source.connection.username
      passwordField.text = source.connection.password

      if isNewSource {
        isEnabledLabel.hidden = true
        isEnabledSwitch.hidden = true
      }
    }

    func setupTextFieldDelegates() {
      nameField.delegate = textFieldDelegate
      urlField.delegate = textFieldDelegate
      usernameField.delegate = textFieldDelegate
      passwordField.delegate = textFieldDelegate

      let fields = [nameField, urlField, usernameField, passwordField]

      for f in fields {
        textFieldDelegate.addOnBeginEditing(f) { [unowned self] tf in
          self.focusedTextField = tf
        }

        textFieldDelegate.addOnEndEditing(f) { [unowned self] tf in
          self.focusedTextField = nil
        }

        textFieldDelegate.addOnShouldReturn(f) { tf in
          tf.resignFirstResponder()
          return true
        }
      }
    }

    func setupBackgroundTap() {
      let tapRecognizer = UITapGestureRecognizer(target: self, action: "backgroundTapped:")
      view.addGestureRecognizer(tapRecognizer)
      view.userInteractionEnabled = true
    }

    super.viewDidLoad()

    resetFontSizes()
    setupSubviews()
    setupTextFieldDelegates()
    setupBackgroundTap()
  }

  override func viewDidLayoutSubviews() {
    contentView.frame = CGRectMake(
      contentView.frame.origin.x,
      contentView.frame.origin.y,
      scrollView.frame.size.width,
      contentView.frame.size.height)

    scrollView.contentSize = CGSizeMake(
      scrollView.frame.size.width,
      contentView.frame.size.height)
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    NSNotificationCenter.defaultCenter().addObserver(
      self,
      selector: "resetFontSizes",
      name: UIContentSizeCategoryDidChangeNotification,
      object: nil)

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

    setupFieldValidation()

    if isNewSource {
      refreshDoneButtonState()
    } else {
      nameFieldValidator.validate()
      urlFieldValidator.validate()
    }
  }

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)

    NSNotificationCenter.defaultCenter().removeObserver(self)

    teardownFieldDelegation()

    if shouldCallDoneCallbackOnViewDisappear {
      let newConnection = VCardSource.Connection(
        url: urlField.text!,
        username: usernameField.text!,
        password: passwordField.text!)

      let newSource = source.with(
        name: nameField.text!.trimmed,
        connection: newConnection,
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

  @IBAction func backgroundTapped(sender: AnyObject) {
    view.endEditing(true)
  }

  // MARK: Notification Handlers

  func keyboardDidShow(notification: NSNotification) {
    // adapted and modified from http://spin.atomicobject.com/2014/03/05/uiscrollview-autolayout-ios/

    func bottomOffset(info: [NSObject: AnyObject]) -> CGFloat {
      let nsvalue = info[UIKeyboardFrameBeginUserInfoKey] as! NSValue
      let orgRect = nsvalue.CGRectValue()
      let convRect = view.convertRect(orgRect, fromView: nil)
      return convRect.size.height
    }

    if let info = notification.userInfo {
      let top = topLayoutGuide.length
      let bottom = bottomOffset(info)
      let contentInsets = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)

      scrollView.contentInset = contentInsets
      scrollView.scrollIndicatorInsets = contentInsets

      if !CGRectContainsPoint(view.frame, focusedTextField.frame.origin) {
        scrollView.scrollRectToVisible(focusedTextField.frame, animated: true)
      }
    }
  }

  func keyboardWillHide(notification: NSNotification) {
    let contentInsets = UIEdgeInsets(
      top: topLayoutGuide.length,
      left: 0,
      bottom: bottomLayoutGuide.length,
      right: 0)
    scrollView.contentInset = contentInsets
    scrollView.scrollIndicatorInsets = contentInsets
  }

  func resetFontSizes() {
    let bodyFont = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
    noticeLabel.font = UIFont.systemFontOfSize(bodyFont.pointSize - 4)
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

  private func setupFieldValidation() {
    nameFieldValidator = TextFieldValidator(
      textField: nameField,
      textFieldDelegate: textFieldDelegate,
      syncValidator: { text in
        return !text.trimmed.isEmpty ? .Success(text) : .Failure(ValidationError.Empty)
      },
      onValidated: { [weak self] result in
        if let s = self {
          s.isValidCurrentName = result.isSuccess
          s.refreshDoneButtonState()
        }
    })

    urlFieldValidator = TextFieldValidator(
      textField: urlField,
      textFieldDelegate: textFieldDelegate,
      asyncValidator: { [weak self] url in
        if let s = self {
          QueueExecution.async(QueueExecution.mainQueue) {
            s.beginURLValidationProgress()
          }
          var username = ""
          var password = ""
          QueueExecution.sync(QueueExecution.mainQueue) {
            username = s.usernameField.text!
            password = s.passwordField.text!
          }
          let connection = VCardSource.Connection(
            url: url,
            username: username,
            password: password)
          return s.checkIsReachableURL(connection)
        } else {
          return Future.failed(ValidationError.Cancelled)
        }
      },
      onValidated: { [weak self] result in
        if let s = self {
          s.isValidCurrentURL = result.isSuccess
          s.endURLValidationProgress(result)
          s.refreshDoneButtonState()
        }
    })

    // oh this is just horrible :(

    let callURLFieldValidatorOnTextChange: ProxyTextFieldDelegate.OnTextChangeCallback = { [weak self] _, _, _ in
      if let s = self {
        s.urlFieldValidator.validate()
      }
      return true
    }

    textFieldDelegate.addOnTextChange(usernameField, callURLFieldValidatorOnTextChange)
    textFieldDelegate.addOnTextChange(passwordField, callURLFieldValidatorOnTextChange)
  }

  private func teardownFieldDelegation() {
    for tf in [nameField, urlField, usernameField, passwordField] {
      textFieldDelegate.removeOnBeginEditing(tf)
      textFieldDelegate.removeOnEndEditing(tf)
      textFieldDelegate.removeOnShouldReturn(tf)
      textFieldDelegate.removeOnTextChange(tf)
    }
  }

  private func beginURLValidationProgress() {
    urlValidationLabel.text = "Validating URL…"

    UIView.animateWithDuration(
      Config.UI.AnimationDurationFadeMessage,
      delay: 0,
      options: [.CurveEaseIn, .BeginFromCurrentState],
      animations: {
        self.urlValidationLabel.alpha = 1
      },
      completion: nil)

    isValidatingURLIndicator.startAnimating()
  }

  private func endURLValidationProgress(result: Try<NSURL>) {
    switch result {
    case .Success:
      urlValidationLabel.text = "URL is valid"
      UIView.animateWithDuration(
        Config.UI.AnimationDurationFadeMessage,
        delay: Config.UI.AnimationDelayFadeOutMessage,
        options: [.CurveEaseOut, .BeginFromCurrentState],
        animations: {
          self.urlValidationLabel.alpha = 0
        },
        completion: nil)
    case .Failure(let error):
      urlValidationLabel.text = (error as NSError).localizedDescription
    }

    isValidatingURLIndicator.stopAnimating()
  }

  private func refreshDoneButtonState() {
    if let button = navigationItem.rightBarButtonItem {
      button.enabled = isValidCurrentName && isValidCurrentURL
    }
  }

  private func checkIsReachableURL(connection: VCardSource.Connection) -> Future<NSURL> {
    if let url = stringToValidHTTPURL(connection.url) {
      let credential = connection.toCredential()
      return self.httpRequests
        .head(url, headers: Config.Net.VCardHTTPHeaders, credential: credential)
        .map { _ in url }
    }
    return Future.failed(Errors.urlIsInvalid())
  }

  private func stringToValidHTTPURL(urlString: String) -> NSURL? {
    if let url = NSURL(string: urlString.trimmed) where url.isValidHTTPURL {
      return url
    } else {
      return nil
    }
  }
}
