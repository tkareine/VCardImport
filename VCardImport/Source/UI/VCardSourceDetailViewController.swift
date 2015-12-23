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
  private let urlDownloadFactory: URLDownloadFactory
  private let doneCallback: VCardSource -> Void
  private let textFieldDelegate: ProxyTextFieldDelegate

  private var shouldCallDoneCallbackOnViewDisappear: Bool
  private var nameFieldValidator: TextFieldValidator<String>!
  private var urlFieldValidator: TextFieldValidator<String>!

  private var isValidCurrentName = false
  private var isValidCurrentURL = false

  private var scrollView: UIScrollView!
  private var contentView: UIView!
  private var focusedTextField: UITextField!

  init(
    source: VCardSource,
    isNewSource: Bool,
    downloadsWith urlDownloadFactory: URLDownloadFactory,
    doneCallback: VCardSource -> Void)
  {
    self.source = source
    self.isNewSource = isNewSource
    self.urlDownloadFactory = urlDownloadFactory
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
    fatalError("init(coder:) has not been implemented")
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
      urlField.text = source.connection.vcardURL
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
        vcardURL: urlField.text!,
        authenticationMethod: .PostForm,
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
    let font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
    noticeLabel.font = font.fontWithSize(font.pointSize - 4)
    nameLabel.font = font
    nameField.font = font
    urlLabel.font = font
    urlField.font = font
    urlValidationLabel.font = font.fontWithSize(font.pointSize - 2)
    usernameLabel.font = font
    usernameField.font = font
    passwordLabel.font = font
    passwordField.font = font
    isEnabledLabel.font = font
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
            vcardURL: url,
            authenticationMethod: .PostForm,
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

  private func endURLValidationProgress(result: Try<String>) {
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

  private func checkIsReachableURL(connection: VCardSource.Connection) -> Future<String> {
    if connection.vcardURLasURL().isValidHTTPURL {
      return urlDownloadFactory
        .makeDownloader(
          connection: connection,
          headers: Config.Net.VCardHTTPHeaders)
        .requestFileHeaders()
        .map { _ in connection.vcardURL }
    }
    return Future.failed(Errors.urlIsInvalid())
  }
}
