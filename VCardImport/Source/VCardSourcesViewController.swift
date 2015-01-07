import UIKit

class VCardSourcesViewController: UITableViewController {
  private typealias ProgressState = (VCardProgress, forSource: VCardSource) -> ()

  private let dataSource: VCardSourcesDataSource

  private var toolbar: VCardToolbar
  private var vcardImporter: VCardImporter!
  private var progressState: ProgressState!

  // MARK: Controller Life Cycle

  init(appContext: AppContext) {
    self.dataSource = VCardSourcesDataSource(vcardSourceStore: appContext.vcardSourceStore)
    self.toolbar = VCardToolbar()

    super.init(nibName: nil, bundle: nil)

    toolbar.importButton.addTarget(
      self,
      action: "importVCardSources:",
      forControlEvents: .TouchUpInside)

    self.navigationItem.title = "vCard Import"
    self.tableView.dataSource = dataSource

    self.vcardImporter = VCardImporter.builder()
      .queue(QueueExecution.mainQueue)
      .onSourceLoad { source in
        self.progressState(.Load, forSource: source)
      }
      .onSourceComplete { source, changes, error in
        if let err = error {
          self.dataSource.setVCardSourceFailureStatus(source, error: err)
        } else {
          self.dataSource.setVCardSourceSuccessStatus(source, changes: changes!)
        }
        self.progressState(.Complete, forSource: source)
        self.reloadTableViewSourceRow(source)
      }
      .onComplete { error in
        if let err = error {
          self.presentAlertForError(err)
        }
        self.endProgress()
        self.refreshSyncButtonEnabledState()
      }
      .build()
  }

  required init(coder decoder: NSCoder) {
    fatalError("not implemented")
  }

  // MARK: View Life Cycle

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.registerClass(VCardSourceCell.self, forCellReuseIdentifier: UIConfig.SourcesCellReuseIdentifier)
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    addToolbarToNavigationController()
    refreshSyncButtonEnabledState()
  }

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    removeToolbarFromNavigationController()
  }

  // MARK: Layout

  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 60.0
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

  func importVCardSources(sender: AnyObject) {
    toolbar.importButton.enabled = false
    let sources = dataSource.enabledVCardSources
    beginProgress(sources)
    vcardImporter.importFrom(sources)
  }

  // MARK: Helpers

  private func refreshSyncButtonEnabledState() {
    toolbar.importButton.enabled = progressState == nil && dataSource.hasEnabledVCardSources
  }

  private func reloadTableViewSourceRow(source: VCardSource) {
    let indexPath = NSIndexPath(forRow: self.dataSource.rowForVCardSource(source), inSection: 0)
    tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
  }

  private func presentAlertForError(error: NSError) {
    let alertController = UIAlertController(
      title: error.localizedFailureReason,
      message: error.localizedDescription,
      preferredStyle: .Alert)
    let dismissAction = UIAlertAction(title: "OK", style: .Default, handler: nil)

    alertController.addAction(dismissAction)

    self.presentViewController(alertController, animated: true, completion: nil)
  }

  private enum VCardProgress {
    case Complete
    case Load
  }

  private func makeProgressState(vcardSources: [VCardSource]) -> ProgressState {
    var lastProgress: Float = 0.0
    let numSources = vcardSources.count
    let sourcesToTrack = vcardSources.map { $0.id }

    func set(type: VCardProgress, forSource source: VCardSource) {
      if !contains(sourcesToTrack, source.id) {
        return  // not tracked source
      }

      let nextProgress = lastProgress + (1.0 / Float(numSources)) * 0.5
      let nextText = type == .Complete ? "Completed \(source.name)" : "Loaded \(source.name)"

      NSLog("Progress: \(nextProgress) \(nextText)")

      self.toolbar.inProgress(nextText, progress: nextProgress)

      lastProgress = nextProgress
    }

    return set
  }

  private func beginProgress(sources: [VCardSource]) {
    progressState = makeProgressState(sources)
    self.toolbar.beginProgress("Loading...")
  }

  private func endProgress() {
    progressState = nil
    QueueExecution.after(5000, QueueExecution.mainQueue) {
      self.toolbar.endProgress()
    }
  }

  func addToolbarToNavigationController() {
    if let nc = navigationController {
      let frame = nc.view.frame
      let toolbarHeight: CGFloat = 58.0

      toolbar.frame = CGRect(
        x: 0,
        y: frame.size.height - toolbarHeight,
        width: frame.width,
        height: toolbarHeight)

      nc.view.addSubview(toolbar)
    }
  }

  func removeToolbarFromNavigationController() {
    if navigationController != nil {
      toolbar.removeFromSuperview()
    }
  }
}
