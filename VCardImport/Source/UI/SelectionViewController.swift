import UIKit

private let CellIdentifier = "SelectionCell"

class SelectionViewController<T>: UIViewController, UITableViewDelegate, UITableViewDataSource {
  private let selectionOptions: [SelectionOption<T>]
  private let onSelect: SelectionOption<T> -> Void
  private let preselectionIndex: Int

  init(
    selectionOptions: [SelectionOption<T>],
    preselectionIndex: Int,
    selectionHandler onSelect: SelectionOption<T> -> Void)
  {
    self.selectionOptions = selectionOptions
    self.preselectionIndex = preselectionIndex
    self.onSelect = onSelect

    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    func makeTableView() -> UITableView {
      let tv = UITableView()
      tv.rowHeight = UITableViewAutomaticDimension
      tv.dataSource = self
      tv.delegate = self
      tv.registerClass(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
      return tv
    }

    view = makeTableView()
  }

  // MARK: UITableViewDelegate

  func tableView(
    tableView: UITableView,
    didSelectRowAtIndexPath indexPath: NSIndexPath)
  {
    onSelect(selectionOptions[indexPath.row])
  }

  // MARK: UITableViewDataSource

  func tableView(
    tableView: UITableView,
    numberOfRowsInSection section: Int)
    -> Int
  {
    return selectionOptions.count
  }

  func tableView(
    tableView: UITableView,
    cellForRowAtIndexPath indexPath: NSIndexPath)
    -> UITableViewCell
  {
    let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier, forIndexPath: indexPath)
    cell.textLabel!.text = selectionOptions[indexPath.row].description
    cell.accessoryType = indexPath.row == preselectionIndex ? .Checkmark : .None
    return cell
  }
}
