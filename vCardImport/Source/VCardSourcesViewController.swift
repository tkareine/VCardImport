import UIKit

class VCardSourcesViewController: UITableViewController {
  private let dataSource: VCardSourcesDataSource
  private let appContext: AppContext

  private var syncButton: UIBarButtonItem!
  private var vcardImporter: VCardImporter!

  // MARK: Controller Life Cycle

  init(appContext: AppContext) {
    self.dataSource = VCardSourcesDataSource(vcardSourceStore: appContext.vcardSourceStore)
    self.appContext = appContext

    super.init(nibName: nil, bundle: nil)

    self.syncButton = UIBarButtonItem(title: "Sync", style: .Plain, target: self, action: "syncVCardSources:")

    self.navigationItem.title = "vCard Import"
    self.toolbarItems = [syncButton]
    self.tableView.dataSource = dataSource

    self.vcardImporter = VCardImporter.builder()
      .onSourceError { source, error in
        NSLog("VCard source error for %@: %@", source.name, error)
      }
      .onFailure { error in
        let alertController = UIAlertController(
          title: error.localizedFailureReason,
          message: error.localizedDescription,
          preferredStyle: .Alert)
        let dismissAction = UIAlertAction(title: "OK", style: .Default, handler: nil)

        alertController.addAction(dismissAction)

        self.presentViewController(alertController, animated: true, completion: nil)

        self.syncButton.enabled = true
      }
      .onSuccess {
        self.syncButton.enabled = true
      }
      .build()
  }

  required init(coder decoder: NSCoder) {
    fatalError("state restoration not supported")
  }

  // MARK: View Life Cycle

  override func viewDidLoad() {
    super.viewDidLoad()
    self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: UIConfig.SourcesCellReuseIdentifier)
  }

  override func viewWillAppear(animated: Bool) {
    syncButton.enabled = appContext.vcardSourceStore.countEnabled > 0
  }

  // MARK: Actions

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let vc = VCardSourceDetailViewController(appContext: appContext, onIndex: indexPath.row) {
      self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
    }
    self.navigationController?.pushViewController(vc, animated: true)
  }

  func syncVCardSources(sender: AnyObject) {
    let enabledSources = appContext.vcardSourceStore.filterEnabled
    syncButton.enabled = false
    vcardImporter.importFrom(enabledSources)
  }
}
