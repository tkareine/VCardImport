import UIKit

class VCardSourcesViewController: UITableViewController {
  private let dataSource: VCardSourcesDataSource
  private let appContext: AppContext

  init(appContext: AppContext) {
    self.dataSource = VCardSourcesDataSource(vcardSourceStore: appContext.vcardSourceStore)
    self.appContext = appContext
    super.init(nibName: nil, bundle: nil)
    self.navigationItem.title = "vCard Import"
    self.tableView.dataSource = dataSource
  }

  required init(coder decoder: NSCoder) {
    fatalError("state restoration not supported")
  }

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let vc = VCardSourceDetailViewController(appContext: appContext, onIndex: indexPath.row) {
      self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
    }
    self.navigationController?.pushViewController(vc, animated: true)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: UIConfig.SourcesCellReuseIdentifier)
  }
}
