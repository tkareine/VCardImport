import UIKit

class RIVCardSourceDetailViewController: UIViewController {
    convenience override init() {
        self.init(nibName: "RIVCardSourceDetailViewController", bundle: nil)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @IBAction func testURL(sender: UIButton) {

    }
}
