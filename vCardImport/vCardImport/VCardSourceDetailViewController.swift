import UIKit

class VCardSourceDetailViewController: UIViewController {
  @IBOutlet weak var sourceURLField: UITextField!

  convenience override init() {
    self.init(nibName: "VCardSourceDetailViewController", bundle: nil)
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  @IBAction func testURL(sender: UIButton) {
    var error: NSError?
    let url = NSURL(string: sourceURLField.text)!
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
