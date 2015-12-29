import UIKit

private let CellIdentifier = "VCardSourceCell"

class VCardSourcesViewController: UIViewController, UITableViewDelegate {
  private let dataSource: VCardSourcesDataSource
  private let urlDownloadFactory: URLDownloadFactory

  private var toolbar: VCardToolbar!
  private var tableView: UITableView!
  private var editButton: UIBarButtonItem!
  private var addButton: UIBarButtonItem!
  private var vcardImporter: VCardImporter!
  private var vcardImportProgress: VCardImportProgress!

  init(appContext: AppContext) {
    dataSource = VCardSourcesDataSource(
      vcardSourceStore: appContext.vcardSourceStore,
      cellReuseIdentifier: CellIdentifier)
    urlDownloadFactory = appContext.urlDownloadFactory

    super.init(nibName: nil, bundle: nil)

    vcardImporter = VCardImporter(
      downloadsWith: urlDownloadFactory,
      queueTo: QueueExecution.mainQueue,
      sourceDownloadHandler: { [weak self] source, progress in
        if let s = self {
          if progress.totalBytesExpected > 0 {
            let ratio = Float(progress.bytes) / Float(progress.totalBytesExpected)
            s.inProgress(.Downloading(completionStepRatio: ratio), forSource: source)
          }
        }
      },
      sourceCompletionHandler: { [weak self] source, recordDiff, modifiedHeaderStamp, error in
        if let s = self {
          if let err = error {
            s.dataSource.setVCardSourceErrorStatus(source, error: err)
          } else if let diff = recordDiff {
            s.dataSource.setVCardSourceChangedStatus(
              source,
              recordDifferences: diff,
              modifiedHeaderStamp: modifiedHeaderStamp)
          } else {
            s.dataSource.setVCardSourceUnchangedStatus(source)
          }
          s.inProgress(.Completed, forSource: source)
          s.reloadTableViewSourceRow(source)
        }
      },
      completionHandler: { [weak self] error in
        if let s = self {
          if let err = error {
            s.presentAlertForError(err)
          }
          s.endProgress()
          s.refreshButtonsEnabledStates()
        }
      })
  }

  required init?(coder decoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    func makeToolbar() -> VCardToolbar {
      let tb = VCardToolbar()
      tb.importButton.addTarget(
        self,
        action: "importVCardSources:",
        forControlEvents: .TouchUpInside)
      return tb
    }

    func makeTableView() -> UITableView {
      let tv = UITableView()
      tv.estimatedRowHeight = 80
      tv.rowHeight = UITableViewAutomaticDimension
      tv.dataSource = dataSource
      tv.delegate = self
      let cellNib = UINib(nibName: CellIdentifier, bundle: nil)
      tv.registerNib(cellNib, forCellReuseIdentifier: CellIdentifier)
      return tv
    }

    toolbar = makeToolbar()
    tableView = makeTableView()

    view = UIView()
    view.addSubview(tableView)
    view.addSubview(toolbar)
  }

  override func viewDidLoad() {
    func setupLayout() {
      let viewNamesToObjects = [
        "tableView": tableView,
        "toolbar": toolbar
      ]

      tableView.translatesAutoresizingMaskIntoConstraints = false
      toolbar.translatesAutoresizingMaskIntoConstraints = false

      NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
        "H:|[tableView]|",
        options: [],
        metrics: nil,
        views: viewNamesToObjects))

      NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
        "H:|[toolbar]|",
        options: [],
        metrics: nil,
        views: viewNamesToObjects))

      NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
        "V:|[tableView][toolbar(==58)]|",
        options: [],
        metrics: nil,
        views: viewNamesToObjects))
    }

    super.viewDidLoad()

    setupLayout()

    editButton = editButtonItem()
    navigationItem.leftBarButtonItem = editButton

    addButton = UIBarButtonItem(
      barButtonSystemItem: .Add,
      target: self,
      action: "addVCardSource:")
    navigationItem.rightBarButtonItem = addButton

    navigationItem.title = Config.Executable
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    refreshButtonsEnabledStates()
  }

  // MARK: UITableViewDelegate

  func tableView(
    tableView: UITableView,
    didSelectRowAtIndexPath indexPath: NSIndexPath)
  {
    let oldSource = dataSource.vCardSourceForRow(indexPath.row)
    let vc = VCardSourceDetailViewController(
      source: oldSource,
      isNewSource: false,
      downloadsWith: urlDownloadFactory) { [unowned self] newSource in
        self.dataSource.saveVCardSource(newSource)
        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
      }
    navigationController!.pushViewController(vc, animated: true)
  }

  // MARK: Actions

  override func setEditing(editing: Bool, animated: Bool) {
    super.setEditing(editing, animated: animated)
    tableView.setEditing(editing, animated: animated)
    refreshButtonsEnabledStates()
  }

  func addVCardSource(sender: AnyObject) {
    let vc = VCardSourceDetailViewController(
      source: VCardSource.empty(),
      isNewSource: true,
      downloadsWith: urlDownloadFactory) { [unowned self] newSource in
        self.dataSource.saveVCardSource(newSource)
        self.tableView.reloadData()
      }
    let nc = UINavigationController(rootViewController: vc)
    nc.modalPresentationStyle = .FormSheet
    presentViewController(nc, animated: true, completion: nil)
  }

  func importVCardSources(sender: AnyObject) {
    let sources = dataSource.enabledVCardSources
    beginProgress(sources)
    refreshButtonsEnabledStates()
    vcardImporter.importFrom(sources)
  }

  // MARK: Helpers

  private func refreshButtonsEnabledStates() {
    addButton.enabled = !editing

    editButton.enabled = dataSource.hasVCardSources

    toolbar.importButton.enabled =
      !editing &&
      vcardImportProgress == nil &&
      dataSource.hasEnabledVCardSources
  }

  private func reloadTableViewSourceRow(source: VCardSource) {
    if let row = dataSource.rowForVCardSource(source) {
      let indexPath = NSIndexPath(forRow: row, inSection: 0)
      tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
    }
  }

  private func presentAlertForError(error: ErrorType) {
    let alertController = UIAlertController(
      title: (error as NSError).localizedFailureReason ?? "Failure",
      message: (error as NSError).localizedDescription,
      preferredStyle: .Alert)
    let dismissAction = UIAlertAction(title: "OK", style: .Default, handler: nil)

    alertController.addAction(dismissAction)

    presentViewController(alertController, animated: true, completion: nil)
  }

  private func beginProgress(sources: [VCardSource]) {
    vcardImportProgress = VCardImportProgress(sourceIds: sources.map { $0.id })
    toolbar.beginProgress("Checking for changes…")
  }

  private func inProgress(
    type: VCardImportProgress.Progress,
    forSource source: VCardSource)
  {
    let progress = vcardImportProgress.step(type, forId: source.id)
    let text = type.describeProgress(source.name)
    NSLog("Import progress: %0.1f%% %@", progress * 100, text)
    toolbar.inProgress(text: text, progress: progress)
  }

  private func endProgress() {
    vcardImportProgress = nil
    toolbar.endProgress()
  }
}
