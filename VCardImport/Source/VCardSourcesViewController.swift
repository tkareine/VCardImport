import UIKit

class VCardSourcesViewController: UITableViewController {
  private typealias ProgressState = (VCardProgress, forSource: VCardSource) -> ()

  private let dataSource: VCardSourcesDataSource
  private let toolbar: VCardToolbar
  private let urlConnection: URLConnection

  private var editButton: UIBarButtonItem!
  private var addButton: UIBarButtonItem!
  private var vcardImporter: VCardImporter!
  private var progressState: ProgressState!

  // MARK: View Controller Life Cycle

  init(appContext: AppContext) {
    dataSource = VCardSourcesDataSource(vcardSourceStore: appContext.vcardSourceStore)
    toolbar = VCardToolbar()
    urlConnection = appContext.urlConnection

    super.init(nibName: nil, bundle: nil)

    editButton = editButtonItem()

    addButton = UIBarButtonItem(
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

    vcardImporter = VCardImporter.builder()
      .connectWith(urlConnection)
      .queueTo(QueueExecution.mainQueue)
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
    let cellNib = UINib(nibName: "VCardSourceCell", bundle: nil)
    tableView.registerNib(cellNib, forCellReuseIdentifier: Config.UI.TableCellReuseIdentifier)
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    tableView.estimatedRowHeight = 95
    tableView.rowHeight = UITableViewAutomaticDimension
    addToolbarToNavigationController()
    refreshButtonsEnabledStates()
  }

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    removeToolbarFromNavigationController()
  }

  // MARK: Table View Customization

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
    let vc = VCardSourceDetailViewController(
      source: oldSource,
      isNewSource: false,
      urlConnection: urlConnection) { newSource in
        self.dataSource.saveVCardSource(newSource)
        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
      }
    self.navigationController!.pushViewController(vc, animated: true)
  }

  func addVCardSource(sender: AnyObject) {
    let vc = VCardSourceDetailViewController(
      source: VCardSource.empty(),
      isNewSource: true,
      urlConnection: urlConnection) { newSource in
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

  // MARK: Environment Changes

  override func viewWillTransitionToSize(
    size: CGSize,
    withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
  {
    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    setToolbarFrame(size)
  }

  // MARK: Helpers

  private func refreshButtonsEnabledStates() {
    addButton.enabled = !editing

    editButton.enabled = dataSource.hasVCardSources

    toolbar.importButton.enabled =
      !editing &&
      progressState == nil &&
      dataSource.hasEnabledVCardSources

    toolbar.backupButton.enabled = false
  }

  private func reloadTableViewSourceRow(source: VCardSource) {
    if let row = self.dataSource.rowForVCardSource(source) {
      let indexPath = NSIndexPath(forRow: row, inSection: 0)
      tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
    }
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
    var lastProgress: Float = 0
    let numSources = vcardSources.count

    func set(type: VCardProgress, forSource source: VCardSource) {
      let nextProgress = lastProgress + (1 / Float(numSources)) * 0.5
      let nextText = type == .Complete ? "Completed \(source.name)" : "Downloaded \(source.name)"

      NSLog("Progress: \(nextProgress) \(nextText)")

      self.toolbar.inProgress(nextText, progress: nextProgress)

      lastProgress = nextProgress
    }

    return set
  }

  private func beginProgress(sources: [VCardSource]) {
    progressState = makeProgressState(sources)
    toolbar.beginProgress("Checking for changes…")
  }

  private func endProgress() {
    progressState = nil
    toolbar.endProgress()
  }

  private func addToolbarToNavigationController() {
    if let nc = navigationController {
      setToolbarFrame(nc.view.frame.size)
      nc.view.addSubview(toolbar)
    }
  }

  private func removeToolbarFromNavigationController() {
    if navigationController != nil {
      toolbar.removeFromSuperview()
    }
  }

  private func setToolbarFrame(size: CGSize) {
    let toolbarHeight: CGFloat = 58
    toolbar.frame = CGRect(
      x: 0,
      y: size.height - toolbarHeight,
      width: size.width,
      height: toolbarHeight)
  }
}
