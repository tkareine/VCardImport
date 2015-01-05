import UIKit

class VCardSourcesViewController: UITableViewController {
  private let dataSource: VCardSourcesDataSource
  private var syncButton: UIBarButtonItem!
  private var vcardImporter: VCardImporter!

  // MARK: Controller Life Cycle

  init(appContext: AppContext) {
    self.dataSource = VCardSourcesDataSource(vcardSourceStore: appContext.vcardSourceStore)

    super.init(nibName: nil, bundle: nil)

    self.syncButton = UIBarButtonItem(title: "Sync", style: .Plain, target: self, action: "syncVCardSources:")

    self.navigationItem.title = "vCard Import"
    self.toolbarItems = [syncButton]
    self.tableView.dataSource = dataSource

    self.vcardImporter = VCardImporter.builder()
      .onSourceFailure { source, error in
        self.dataSource.setVCardSourceFailureStatus(source, error: error)
        self.reloadTableViewSourceRow(source)
      }
      .onSourceSuccess { source, changes in
        self.dataSource.setVCardSourceSuccessStatus(source, changes: changes)
        self.reloadTableViewSourceRow(source)
      }
      .onFailure { error in
        let alertController = UIAlertController(
          title: error.localizedFailureReason,
          message: error.localizedDescription,
          preferredStyle: .Alert)
        let dismissAction = UIAlertAction(title: "OK", style: .Default, handler: nil)

        alertController.addAction(dismissAction)

        self.presentViewController(alertController, animated: true, completion: nil)

        self.refreshSyncButtonEnabledState()
      }
      .onSuccess {
        self.refreshSyncButtonEnabledState()
      }
      .build()
  }

  required init(coder decoder: NSCoder) {
    fatalError("state restoration not supported")
  }

  // MARK: View Life Cycle

  override func viewDidLoad() {
    super.viewDidLoad()
    self.tableView.registerClass(VCardSourceCell.self, forCellReuseIdentifier: UIConfig.SourcesCellReuseIdentifier)
  }

  override func viewWillAppear(animated: Bool) {
    refreshSyncButtonEnabledState()
  }

  // MARK: Actions

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let oldSource = dataSource.vCardSourceForRow(indexPath.row)
    let vc = VCardSourceDetailViewController(source: oldSource) { newSource in
      self.dataSource.saveVCardSource(newSource)
      self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
    }
    self.navigationController?.pushViewController(vc, animated: true)
  }

  func syncVCardSources(sender: AnyObject) {
    syncButton.enabled = false
    vcardImporter.importFrom(dataSource.enabledVCardSources)
  }

  // MARK: Helpers

  private func refreshSyncButtonEnabledState() {
    syncButton.enabled = dataSource.hasEnabledVCardSources
  }

  private func reloadTableViewSourceRow(source: VCardSource) {
    let indexPath = NSIndexPath(forRow: self.dataSource.rowForVCardSource(source), inSection: 0)
    self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
  }
}
