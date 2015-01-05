import UIKit

class VCardSourceDetailViewController: UIViewController {
  @IBOutlet weak var nameField: UITextField!
  @IBOutlet weak var urlField: UITextField!
  @IBOutlet weak var isEnabledSwitch: UISwitch!

  private let source: VCardSource
  private let doneCallback: VCardSource -> Void

  // MARK: Controller Life Cycle

  init(source: VCardSource, doneCallback: VCardSource -> Void) {
    self.source = source
    self.doneCallback = doneCallback
    super.init(nibName: "VCardSourceDetailViewController", bundle: nil)
  }

  required init(coder decoder: NSCoder) {
    fatalError("state restoration not supported")
  }

  // MARK: View Life Cycle

  override func viewWillAppear(animated: Bool) {
    super.viewWillDisappear(animated)
    nameField.text = source.name
    urlField.text = source.connection.url.absoluteString
    isEnabledSwitch.on = source.isEnabled
  }

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)

    let urlCandidate = NSURL(string: urlField.text)
    let newURL = urlCandidate != nil ? urlCandidate! : source.connection.url

    let newSource = source.withName(
      nameField.text,
      connection: VCardSource.Connection(url: newURL),
      isEnabled: isEnabledSwitch.on
    )

    doneCallback(newSource)
  }

  // MARK: Actions

  @IBAction func testConnection(sender: UIButton) {
    NSLog("Test connection")
  }
}
