import UIKit

class VCardSourceDetailViewController: UIViewController {
  @IBOutlet weak var nameField: UITextField!
  @IBOutlet weak var urlField: UITextField!
  @IBOutlet weak var isEnabledLabel: UILabel!
  @IBOutlet weak var isEnabledSwitch: UISwitch!

  private let source: VCardSource
  private let isNewSource: Bool
  private let doneCallback: VCardSource -> Void
  private var shouldCallDoneCallbackOnViewDisappear: Bool

  private var nameFieldValidator: TextFieldValidator!

  // MARK: Controller Life Cycle

  init(source: VCardSource, isNewSource: Bool, doneCallback: VCardSource -> Void) {
    self.source = source
    self.isNewSource = isNewSource
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
      validator: { !$0.isEmpty },
      onValidated: { [unowned self] isValid in
        self.navigationItem.rightBarButtonItem?.enabled = isValid
        // Needed for Swift's type inferencer. Without explicit return, we get
        // error: Cannot convert the expression's type '()' to type '$T14?'
        return
    })

    nameField.text = source.name
    urlField.text = source.connection.url.absoluteString
    isEnabledSwitch.on = source.isEnabled

    if isNewSource {
      isEnabledLabel.hidden = true
      isEnabledSwitch.hidden = true
    }

    nameFieldValidator.validate(affectStyle: !isNewSource)
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

  @IBAction func testConnection(sender: UIButton) {
    NSLog("Test connection")
  }
}
