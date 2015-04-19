import UIKit

class VCardSourcesViewController: UIViewController, UITableViewDelegate {
  private let dataSource: VCardSourcesDataSource
  private let urlConnection: URLConnectable

  private var toolbar: VCardToolbar!
  private var tableView: UITableView!
  private var editButton: UIBarButtonItem!
  private var addButton: UIBarButtonItem!
  private var vcardImporter: VCardImporter!
  private var vcardImportProgress: VCardImportProgress!

  // MARK: View Controller Life Cycle

  init(appContext: AppContext) {
    dataSource = VCardSourcesDataSource(vcardSourceStore: appContext.vcardSourceStore)
    urlConnection = appContext.urlConnection

    super.init(nibName: nil, bundle: nil)

    vcardImporter = VCardImporter.builder()
      .connectWith(urlConnection)
      .queueTo(QueueExecution.mainQueue)
      .onSourceDownload { [weak self] source, progress in
        if let s = self {
          if progress.totalBytesExpected > 0 {
            let ratio = Float(progress.bytes) / Float(progress.totalBytesExpected)
            s.inProgress(.Downloading(completionStepRatio: ratio), forSource: source)
          }
        }
      }
      .onSourceComplete { [weak self] source, recordDiff, modifiedHeaderStamp, error in
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
      tv.estimatedRowHeight = 95
      tv.rowHeight = UITableViewAutomaticDimension
      tv.dataSource = dataSource
      tv.delegate = self
      let cellNib = UINib(nibName: "VCardSourceCell", bundle: nil)
      tv.registerNib(cellNib, forCellReuseIdentifier: Config.UI.TableCellReuseIdentifier)
      return tv
    }

    func setupLayout() {
      let viewNamesToObjects = [
        "tableView": tableView,
        "toolbar": toolbar
      ]

      tableView.setTranslatesAutoresizingMaskIntoConstraints(false)
      toolbar.setTranslatesAutoresizingMaskIntoConstraints(false)

      view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
        "H:|[tableView]|",
        options: nil,
        metrics: nil,
        views: viewNamesToObjects))

      view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
        "H:|[toolbar]|",
        options: nil,
        metrics: nil,
        views: viewNamesToObjects))

      view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
        "V:|[tableView][toolbar(==58)]|",
        options: nil,
        metrics: nil,
        views: viewNamesToObjects))
    }

    super.viewDidLoad()

    toolbar = makeToolbar()
    tableView = makeTableView()

    view.addSubview(tableView)
    view.addSubview(toolbar)

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
      urlConnection: urlConnection) { newSource in
        self.dataSource.saveVCardSource(newSource)
        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
      }
    self.navigationController!.pushViewController(vc, animated: true)
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
