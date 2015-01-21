import UIKit

class VCardSourceDetailViewController: UIViewController {
  private let source: VCardSource
  private let isNewSource: Bool
  private let urlConnection: URLConnection
  private let doneCallback: VCardSource -> Void

  private var shouldCallDoneCallbackOnViewDisappear: Bool
  private var nameFieldValidator: TextFieldValidator<String>!
  private var urlFieldValidator: TextFieldValidator<NSURL>!

  private var lastValidName: String?
  private var lastValidURL: NSURL?

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
      syncValidator: { [weak self] text in
        self?.isValidCurrentName = false
        return !text.isEmpty ? .Success(text) : .Failure("empty")
      },
      onValidated: { [weak self] result in
        if let s = self {
          if result.isSuccess {
            s.lastValidName = result.value!
            s.isValidCurrentName = true
          }
          s.refreshDoneButtonState()
        }
      })

    urlFieldValidator = TextFieldValidator(
      textField: detailViewOwner.urlField,
      asyncValidator: { [weak self] url in
        if let s = self {
          s.isValidCurrentURL = false
          QueueExecution.async(QueueExecution.mainQueue) {
            s.detailViewOwner.beginURLValidationProgress()
          }
          return s.checkIsReachableURL(url)
        } else {
          return Future.failed("view disappeared")
        }
      },
      onValidated: { [weak self] result in
        if let s = self {
          if result.isSuccess {
            s.lastValidURL = result.value!
            s.isValidCurrentURL = true
          }
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
      let newName = lastValidName ?? source.name
      let newURL = lastValidURL ?? source.connection.url

      let newSource = source.with(
        name: newName,
        connection: VCardSource.Connection(url: newURL),
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
    let owner = VCardSourceDetailViewOwner()
    owner.loadView(source: source, isNewSource: isNewSource)
    return owner
  }

  private func setupView() {
    let scrollView = makeScrollView()
    detailViewOwner = makeDetailViewOwner()

    scrollView.addSubview(detailViewOwner.view)
    view.addSubview(scrollView)

    setupLayout(scrollView: scrollView, contentView: detailViewOwner.view)
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

  private func checkIsReachableURL(urlString: String) -> Future<NSURL> {
    if let url = NSURL(string: urlString) {
      if url.isValidHTTPURL {
        return self.urlConnection
          .head(url, headers: Config.Net.VCardHTTPHeaders)
          .map { _ in url }
      }
    }
    return Future.failed("Invalid URL")
  }
}
