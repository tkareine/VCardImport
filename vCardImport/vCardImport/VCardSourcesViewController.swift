import UIKit

class VCardSourcesViewController: UITableViewController {
  private let dataSource: VCardSourcesDataSource
  private let appContext: AppContext

  // MARK: Controller Life Cycle

  init(appContext: AppContext) {
    self.dataSource = VCardSourcesDataSource(vcardSourceStore: appContext.vcardSourceStore)
    self.appContext = appContext
    super.init(nibName: nil, bundle: nil)
    self.navigationItem.title = "vCard Import"
    self.toolbarItems = [UIBarButtonItem(title: "Sync", style: .Plain, target: self, action: "syncVCardSources:")]
    self.tableView.dataSource = dataSource
  }

  required init(coder decoder: NSCoder) {
    fatalError("state restoration not supported")
  }

  // MARK: View Life Cycle

  override func viewDidLoad() {
    super.viewDidLoad()
    self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: UIConfig.SourcesCellReuseIdentifier)
  }

  // MARK: Actions

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let vc = VCardSourceDetailViewController(appContext: appContext, onIndex: indexPath.row) {
      self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
    }
    self.navigationController?.pushViewController(vc, animated: true)
  }

  func syncVCardSources(sender: AnyObject) {
    if let source = appContext.vcardSourceStore.first {
      var error: NSError?
      let url = source.connection.url
      let success = appContext.vcardImporter.importFrom(url, error: &error)
      if (!success) {
        let alertController = UIAlertController(
          title: error?.localizedFailureReason,
          message: error?.localizedDescription,
          preferredStyle: .Alert)
        let dismissAction = UIAlertAction(title: "OK", style: .Default, handler: nil)

        alertController.addAction(dismissAction)

        presentViewController(alertController, animated: true, completion: nil);
      }
    }
  }
}
