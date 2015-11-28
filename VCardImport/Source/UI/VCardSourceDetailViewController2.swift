import UIKit

class VCardSourceDetailViewController2: UIViewController, UITableViewDelegate, UITableViewDataSource {
  private let source: VCardSource
  private let isNewSource: Bool
  private let urlDownloadFactory: URLDownloadFactory
  private let onDisappear: VCardSource -> Void

  private var tableView: UITableView!

  private var headerView: MultilineLabel!
  private var nameCell: LabeledTextFieldCell!
  private var fileURLCell: LabeledTextFieldCell!
  private var loginURLCell: LabeledTextFieldCell!
  private var authMethodCell: LabeledSelectionCell<HTTPRequest.AuthenticationMethod>!
  private var usernameCell: LabeledTextFieldCell!
  private var passwordCell: LabeledTextFieldCell!
  private var isEnabledCell: LabeledSwitchCell!

  private var cellsByIndexPath: [Int: [Int: UITableViewCell]]!

  private var shouldCallOnDisappearCallback: Bool

  init(
    source: VCardSource,
    isNewSource: Bool,
    downloadsWith urlDownloadFactory: URLDownloadFactory,
    disappearHandler onDisappear: VCardSource -> Void)
  {
    self.source = source
    self.isNewSource = isNewSource
    self.urlDownloadFactory = urlDownloadFactory
    self.onDisappear = onDisappear
    self.shouldCallOnDisappearCallback = !isNewSource

    super.init(nibName: nil, bundle: nil)

    if isNewSource {
      navigationItem.title = Config.UI.VCardNewSourceHeader

      navigationItem.leftBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .Cancel,
        target: self,
        action: "cancel:")

      navigationItem.rightBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .Done,
        target: self,
        action: "done:")
    }
  }

  required init?(coder decoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    func makeTableView() -> UITableView {
      let tv = UITableView(frame: CGRect(), style: .Grouped)
      tv.delegate = self
      tv.dataSource = self
      return tv
    }

    func setupBackgroundTapTo(view: UIView) {
      let tapRecognizer = UITapGestureRecognizer(target: self, action: "backgroundTapped:")
      tapRecognizer.cancelsTouchesInView = false
      view.addGestureRecognizer(tapRecognizer)
    }

    nameCell = LabeledTextFieldCell(
      label: "Name",
      value: source.name,
      autocapitalizationType: .Sentences,
      autocorrectionType: .Yes,
      spellCheckingType: .Default)

    fileURLCell = LabeledTextFieldCell(label: "vCard URL", value: source.connection.url)
    loginURLCell = LabeledTextFieldCell(label: "Login URL", value: source.connection.loginURL ?? "")

    authMethodCell = makeAuthMethodCell()

    usernameCell = LabeledTextFieldCell(label: "Username", value: source.connection.username)

    passwordCell = LabeledTextFieldCell(label: "Password", value: source.connection.password, isSecure: true)

    isEnabledCell = LabeledSwitchCell(label: "Enabled", isEnabled: source.isEnabled)

    cellsByIndexPath = makeCellsByIndexPath()

    headerView = MultilineLabel(frame: CGRect(), labelText: Config.UI.VCardSourceNoteText)

    tableView = makeTableView()

    tableView.tableHeaderView = headerView

    view = tableView

    setupBackgroundTapTo(view)
  }

  override func viewWillLayoutSubviews() {
    // adapted from <http://roadfiresoftware.com/2015/05/how-to-size-a-table-header-view-using-auto-layout-in-interface-builder/>

    super.viewWillLayoutSubviews()

    headerView.setNeedsLayout()
    headerView.layoutIfNeeded()

    var frame = headerView.frame
    frame.size = headerView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
    headerView.frame = frame

    tableView.tableHeaderView = headerView
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    if let previousSelection = tableView.indexPathForSelectedRow {
      tableView.deselectRowAtIndexPath(previousSelection, animated: true)
    }
  }

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)

    if shouldCallOnDisappearCallback {
      let authenticationMethod = authMethodCell.selection.data

      let newConnection = VCardSource.Connection(
        url: fileURLCell.currentText,
        authenticationMethod: authenticationMethod,
        username: usernameCell.currentText,
        password: passwordCell.currentText,
        loginURL: authenticationMethod == .PostForm ? loginURLCell.currentText : nil)

      let newSource = source.with(
        name: nameCell.currentText.trimmed,
        connection: newConnection,
        isEnabled: isEnabledCell.on
      )

      onDisappear(newSource)
    }
  }

  // MARK: UITableViewDelegate

  func tableView(
    tableView: UITableView,
    shouldHighlightRowAtIndexPath indexPath: NSIndexPath)
    -> Bool
  {
    return cellAtIndexPath(indexPath) === authMethodCell
  }

  func tableView(
    tableView: UITableView,
    heightForHeaderInSection section: Int)
    -> CGFloat
  {
    if section == 0 {
      return 0.0
    }
    return 10.0
  }

  func tableView(
    tableView: UITableView,
    didSelectRowAtIndexPath indexPath: NSIndexPath)
  {
    if let cell = cellAtIndexPath(indexPath) where cell === authMethodCell {
      let selectionOptions = HTTPRequest.AuthenticationMethod.allValues.map {
        SelectionOption(description: $0.usageDescription, data: $0)
      }
      let selectedAuthMethod = authMethodCell.selection.data
      let preselectionIndex = selectionOptions.findIndexWhere({ $0.data == selectedAuthMethod })!
      let vc = SelectionViewController(
        selectionOptions: selectionOptions,
        preselectionIndex: preselectionIndex
        ) { [unowned self] selectedOption in
          self.navigationController!.popViewControllerAnimated(true)
          self.authMethodCell.selection = selectedOption
          if selectedOption.data != selectedAuthMethod {
            let loginURLCellIndexPath = self.indexPathOfLoginURLCell()
            if selectedOption.data == .PostForm {
              self.tableView.insertRowsAtIndexPaths([loginURLCellIndexPath], withRowAnimation: .Fade)
            } else {
              self.tableView.deleteRowsAtIndexPaths([loginURLCellIndexPath], withRowAnimation: .Fade)
            }
          }
      }
      navigationController!.pushViewController(vc, animated: true)
    }
  }

  // MARK: UITableViewDataSource

  func tableView(
    tableView: UITableView,
    cellForRowAtIndexPath indexPath: NSIndexPath)
    -> UITableViewCell
  {
    guard let cell = cellAtIndexPath(indexPath) else {
      fatalError("unknown indexPath: \(indexPath)")
    }
    return cell
  }

  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return cellsByIndexPath.count
  }

  func tableView(
    tableView: UITableView,
    numberOfRowsInSection section: Int)
    -> Int
  {
    if let rows = cellsByIndexPath[section] {
      return section == 0 && authMethodCell.selection.data != .PostForm
        ? rows.count - 1
        : rows.count
    }
    fatalError("unknown section: \(section)")
  }

  // MARK: Actions

  func cancel(sender: AnyObject) {
    presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
  }

  func done(sender: AnyObject) {
    shouldCallOnDisappearCallback = true
    presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
  }

  func backgroundTapped(sender: AnyObject) {
    view.endEditing(true)
  }

  // MARK: Helpers

  private func makeAuthMethodCell() -> LabeledSelectionCell<HTTPRequest.AuthenticationMethod> {
    return LabeledSelectionCell(
      label: "Authentication",
      selection: SelectionOption(
        description: source.connection.authenticationMethod.usageDescription,
        data: source.connection.authenticationMethod))
  }

  private func makeCellsByIndexPath() -> [Int: [Int: UITableViewCell]] {
    return [
      0: [
        0: nameCell,
        1: fileURLCell,
        2: loginURLCell
      ],
      1: [
        0: authMethodCell,
        1: usernameCell,
        2: passwordCell
      ],
      2: [
        0: isEnabledCell
      ]
    ]
  }

  private func indexPathOfLoginURLCell() -> NSIndexPath {
    return NSIndexPath(forRow: 2, inSection: 0)
  }

  private func cellAtIndexPath(indexPath: NSIndexPath) -> UITableViewCell? {
    if let
      rows = cellsByIndexPath[indexPath.section],
      cell = rows[indexPath.row] {
        return cell
    }
    return nil
  }
}
