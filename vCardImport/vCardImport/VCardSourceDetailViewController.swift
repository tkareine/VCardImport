import UIKit

class VCardSourceDetailViewController: UIViewController {
  @IBOutlet weak var nameField: UITextField!
  @IBOutlet weak var urlField: UITextField!

  private var source: VCardSource
  private var doneCallback: ((VCardSource) -> Void)

  init(source: VCardSource, doneCallback: (VCardSource) -> Void) {
    self.source = source
    self.doneCallback = doneCallback
    super.init(nibName: "VCardSourceDetailViewController", bundle: nil)
  }

  required init(coder decoder: NSCoder) {
    fatalError("state restoration not supported")
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillDisappear(animated)
    nameField.text = source.name
    urlField.text = source.connection.url
  }

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    let newSource = VCardSource(name: nameField.text, connection: VCardSource.Connection(url: urlField.text))
    doneCallback(newSource)
  }

  @IBAction func testURL(sender: UIButton) {
    var error: NSError?
    let url = NSURL(string: urlField.text)!
    let success = VCardImporter.sharedImporter.importFrom(url, error: &error)
    if (!success) {
      let alertController = UIAlertController(title: error?.localizedFailureReason,
        message: error?.localizedDescription,
        preferredStyle: .Alert)
      let dismissAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
      alertController.addAction(dismissAction)

      presentViewController(alertController, animated: true, completion: nil);
    }
  }
}
