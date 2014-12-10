import UIKit

class VCardSourceDetailViewController: UIViewController {
  @IBOutlet weak var nameField: UITextField!
  @IBOutlet weak var urlField: UITextField!

  private let appContext: AppContext
  private let sourceIndex: Int
  private let source: VCardSource
  private let doneCallback: () -> Void

  // MARK: Controller Life Cycle

  init(appContext: AppContext, onIndex: Int, doneCallback: () -> Void) {
    self.appContext = appContext
    self.sourceIndex = onIndex
    self.source = appContext.vcardSourceStore[sourceIndex]
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
  }

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)

    let urlCandidate = NSURL(string: urlField.text)
    let newURL = urlCandidate != nil ? urlCandidate! : source.connection.url

    let newSource = VCardSource(
      name: nameField.text,
      connection: VCardSource.Connection(url: newURL)
    )

    appContext.vcardSourceStore[sourceIndex] = newSource
    appContext.vcardSourceStore.save()

    doneCallback()
  }

  // MARK: Actions

  @IBAction func testConnection(sender: UIButton) {
    NSLog("Test connection")
  }
}
