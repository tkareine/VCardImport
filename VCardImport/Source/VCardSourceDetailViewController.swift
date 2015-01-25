import UIKit

class VCardSourceDetailViewController: UIViewController {
  private let source: VCardSource
  private let isNewSource: Bool
  private let urlConnection: URLConnection
  private let doneCallback: VCardSource -> Void
  private let textFieldDelegate: ProxyTextFieldDelegate

  private var shouldCallDoneCallbackOnViewDisappear: Bool
  private var nameFieldValidator: TextFieldValidator<String>!
  private var urlFieldValidator: TextFieldValidator<NSURL>!

  private var isValidCurrentName = false
  private var isValidCurrentURL = false

  private var detailViewOwner: VCardSourceDetailViewOwner!

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
    textFieldDelegate = ProxyTextFieldDelegate()

    shouldCallDoneCallbackOnViewDisappear = !isNewSource

    super.init(nibName: nil, bundle: nil)

    if isNewSource {
      navigationItem.title = "Add vCard Source"
      navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancel:")
      navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "done:")
    }
  }

  required init(coder decoder: NSCoder) {
    fatalError("not implemented")
  }

  // MARK: View Life Cycle

  override func viewDidLoad() {
    super.viewDidLoad()

    setupView()

    nameFieldValidator = TextFieldValidator(
      textField: detailViewOwner.nameField,
      textFieldDelegate: textFieldDelegate,
      syncValidator: { [weak self] text in
        return !text.trimmed.isEmpty ? .Success(text) : .Failure("empty")
      },
      onValidated: { [weak self] result in
        if let s = self {
          s.isValidCurrentName = result.isSuccess
          s.refreshDoneButtonState()
        }
      })

    urlFieldValidator = TextFieldValidator(
      textField: detailViewOwner.urlField,
      textFieldDelegate: textFieldDelegate,
      asyncValidator: { [weak self] url in
        if let s = self {
          QueueExecution.async(QueueExecution.mainQueue) {
            s.detailViewOwner.beginURLValidationProgress()
          }
          var username = ""
          var password = ""
          QueueExecution.sync(QueueExecution.mainQueue) {
            username = s.detailViewOwner.usernameField.text
            password = s.detailViewOwner.passwordField.text
          }
          let connection = VCardSource.Connection(
            url: url,
            username: username,
            password: password)
          return s.checkIsReachableURL(connection)
        } else {
          return Future.failed("view disappeared")
        }
      },
      onValidated: { [weak self] result in
        if let s = self {
          s.isValidCurrentURL = result.isSuccess
          s.detailViewOwner.endURLValidationProgress(result)
          s.refreshDoneButtonState()
        }
      })
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    if isNewSource {
      refreshDoneButtonState()
    } else {
      nameFieldValidator.validate()
      urlFieldValidator.validate()
    }
  }

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)

    if shouldCallDoneCallbackOnViewDisappear {
      let newConnection = VCardSource.Connection(
        url: detailViewOwner.urlField.text,
        username: detailViewOwner.usernameField.text,
        password: detailViewOwner.passwordField.text)

      let newSource = source.with(
        name: detailViewOwner.nameField.text.trimmed,
        connection: newConnection,
        isEnabled: detailViewOwner.isEnabledSwitch.on
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

  private func makeScrollView() -> UIScrollView {
    let sv = UIScrollView()
    sv.backgroundColor = UIColor.whiteColor()
    sv.setTranslatesAutoresizingMaskIntoConstraints(false)
    return sv
  }

  private func makeDetailViewOwner() -> VCardSourceDetailViewOwner {
    let owner = VCardSourceDetailViewOwner(textFieldDelegate: textFieldDelegate)
    owner.loadView(source: source, isNewSource: isNewSource)
    return owner
  }

  private func setupView() {
    let scrollView = makeScrollView()
    detailViewOwner = makeDetailViewOwner()

    scrollView.addSubview(detailViewOwner.view)
    view.addSubview(scrollView)

    setupLayout(scrollView: scrollView, contentView: detailViewOwner.view)

    detailViewOwner.setScrollingToFocusedTextField(
      containerView: view,
      scrollView: scrollView,
      navigationController: navigationController)
  }

  private func setupLayout(#scrollView: UIScrollView, contentView: UIView) {
    let viewNamesToObjects = [
      "scrollView": scrollView,
      "contentView": contentView
    ]

    view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
      "H:|[scrollView]|",
      options: nil,
      metrics: nil,
      views: viewNamesToObjects))

    view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
      "V:|[scrollView]|",
      options: nil,
      metrics: nil,
      views: viewNamesToObjects))

    scrollView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
      "H:|[contentView]|",
      options: nil,
      metrics: nil,
      views: viewNamesToObjects))

    scrollView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
      "V:|[contentView]|",
      options: nil,
      metrics: nil,
      views: viewNamesToObjects))

    view.addConstraint(NSLayoutConstraint(
      item: contentView,
      attribute: .Leading,
      relatedBy: .Equal,
      toItem: view,
      attribute: .Left,
      multiplier: 1,
      constant: 0))

    view.addConstraint(NSLayoutConstraint(
      item: contentView,
      attribute: .Trailing,
      relatedBy: .Equal,
      toItem: view,
      attribute: .Right,
      multiplier: 1,
      constant: 0))
  }

  private func refreshDoneButtonState() {
    if let button = navigationItem.rightBarButtonItem {
      button.enabled = isValidCurrentName && isValidCurrentURL
    }
  }

  private func checkIsReachableURL(connection: VCardSource.Connection) -> Future<NSURL> {
    if let url = stringToValidHTTPURL(connection.url) {
      let credential = connection.toCredential()
      return self.urlConnection
        .head(url, headers: Config.Net.VCardHTTPHeaders, credential: credential)
        .map { _ in url }
    }
    return Future.failed("Invalid URL")
  }

  private func stringToValidHTTPURL(urlString: String) -> NSURL? {
    if let url = NSURL(string: urlString.trimmed) {
      if url.isValidHTTPURL {
        return url
      }
    }
    return nil
  }
}
