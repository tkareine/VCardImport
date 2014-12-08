import UIKit

class VCardSourcesViewController: UITableViewController {
  let CellReuseIdentifier = "UITableViewCell"

  override init() {
    super.init(nibName: nil, bundle: nil)
    self.navigationItem.title = "vCard Import"
  }

  convenience override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    self.init()
  }

  required init(coder decoder: NSCoder) {
    fatalError("state restoration not supported")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: CellReuseIdentifier)
  }

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return VCardSourceStore.sharedStore.count
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier(CellReuseIdentifier, forIndexPath: indexPath) as UITableViewCell
    cell.textLabel?.text = getSource(at: indexPath.row).name
    return cell
  }

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let vc = VCardSourceDetailViewController(source: getSource(at: indexPath.row)) { newSource in
      VCardSourceStore.sharedStore[indexPath.row] = newSource
      self.tableView.reloadData()
    }
    self.navigationController?.pushViewController(vc, animated: true)
  }

  private func getSource(at index: Int) -> VCardSource {
    return VCardSourceStore.sharedStore[index]
  }
}
