import UIKit

class VCardSourcesViewController: UITableViewController {
  private typealias ProgressState = (VCardProgress, forSource: VCardSource) -> ()

  private let dataSource: VCardSourcesDataSource

  private var editButton: UIBarButtonItem!
  private var addButton: UIBarButtonItem!
  private var toolbar: VCardToolbar
  private var vcardImporter: VCardImporter!
  private var progressState: ProgressState!

  // MARK: View Controller Life Cycle

  init(appContext: AppContext) {
    self.dataSource = VCardSourcesDataSource(vcardSourceStore: appContext.vcardSourceStore)
    self.toolbar = VCardToolbar()

    super.init(nibName: nil, bundle: nil)

    self.editButton = editButtonItem()

    self.addButton = UIBarButtonItem(
      barButtonSystemItem: .Add,
      target: self,
      action: "addVCardSource:")

    toolbar.importButton.addTarget(
      self,
      action: "importVCardSources:",
      forControlEvents: .TouchUpInside)

    self.navigationItem.title = Config.AppTitle
    self.navigationItem.leftBarButtonItem = editButton
    self.navigationItem.rightBarButtonItem = addButton
    self.tableView.dataSource = dataSource

    self.vcardImporter = VCardImporter.builder()
      .urlConnection(appContext.urlConnection)
      .queue(QueueExecution.mainQueue)
      .onSourceLoad { source in
        self.progressState(.Load, forSource: source)
      }
      .onSourceComplete { source, changes, modifiedHeaderStamp, error in
        if let err = error {
          self.dataSource.setVCardSourceFailureStatus(source, error: err)
        } else {
          self.dataSource.setVCardSourceSuccessStatus(
            source,
            changes: changes!,
            modifiedHeaderStamp: modifiedHeaderStamp)
        }
        self.progressState(.Complete, forSource: source)
        self.reloadTableViewSourceRow(source)
      }
      .onComplete { error in
        if let err = error {
          self.presentAlertForError(err)
        }
        self.endProgress()
        self.refreshButtonsEnabledStates()
      }
      .build()
  }

  required init(coder decoder: NSCoder) {
    fatalError("not implemented")
  }

  // MARK: View Life Cycle

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.registerClass(
      VCardSourceCell.self,
      forCellReuseIdentifier: Config.UI.SourcesCellReuseIdentifier)
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    addToolbarToNavigationController()
    refreshButtonsEnabledStates()
  }

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    removeToolbarFromNavigationController()
  }

  // MARK: Table View Customization

  override func tableView(
    tableView: UITableView,
    heightForRowAtIndexPath indexPath: NSIndexPath)
    -> CGFloat
  {
    return 60.0
  }

  override func setEditing(editing: Bool, animated: Bool) {
    super.setEditing(editing, animated: animated)
    refreshButtonsEnabledStates()
  }

  // MARK: Actions

  override func tableView(
    tableView: UITableView,
    didSelectRowAtIndexPath indexPath: NSIndexPath)
  {
    let oldSource = dataSource.vCardSourceForRow(indexPath.row)
    let vc = VCardSourceDetailViewController(source: oldSource, isNewSource: false) { newSource in
      self.dataSource.saveVCardSource(newSource)
      self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
    }
    self.navigationController!.pushViewController(vc, animated: true)
  }

  func addVCardSource(sender: AnyObject) {
    let vc = VCardSourceDetailViewController(source: VCardSource.empty(), isNewSource: true) { newSource in
      self.dataSource.saveVCardSource(newSource)
      self.tableView.reloadData()
    }
    let nc = UINavigationController(rootViewController: vc)
    nc.modalPresentationStyle = .FormSheet
    self.presentViewController(nc, animated: true, completion: nil)
  }

  func importVCardSources(sender: AnyObject) {
    let sources = dataSource.enabledVCardSources
    beginProgress(sources)
    refreshButtonsEnabledStates()
    vcardImporter.importFrom(sources)
  }

  // MARK: Helpers

  private func refreshButtonsEnabledStates() {
    addButton.enabled = !editing && progressState == nil

    editButton.enabled = dataSource.hasVCardSources && progressState == nil

    toolbar.importButton.enabled =
      !editing &&
      progressState == nil &&
      dataSource.hasEnabledVCardSources

    toolbar.backupButton.enabled = false
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

    func set(type: VCardProgress, forSource source: VCardSource) {
      let nextProgress = lastProgress + (1.0 / Float(numSources)) * 0.5
      let nextText = type == .Complete ? "Completed \(source.name)" : "Downloaded \(source.name)"

      NSLog("Progress: \(nextProgress) \(nextText)")

      self.toolbar.inProgress(nextText, progress: nextProgress)

      lastProgress = nextProgress
    }

    return set
  }

  private func beginProgress(sources: [VCardSource]) {
    progressState = makeProgressState(sources)
    toolbar.beginProgress("Downloading…")
  }

  private func endProgress() {
    progressState = nil
    QueueExecution.after(5000, QueueExecution.mainQueue) {
      self.toolbar.endProgress()
    }
  }

  private func addToolbarToNavigationController() {
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

  private func removeToolbarFromNavigationController() {
    if navigationController != nil {
      toolbar.removeFromSuperview()
    }
  }
}
