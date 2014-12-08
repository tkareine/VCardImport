import UIKit

class VCardSourcesViewController: UITableViewController {
  private let CellReuseIdentifier = "UITableViewCell"
  private let appContext: AppContext

  init(appContext: AppContext) {
    self.appContext = appContext
    super.init(nibName: nil, bundle: nil)
    self.navigationItem.title = "vCard Import"
  }

  required init(coder decoder: NSCoder) {
    fatalError("state restoration not supported")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: CellReuseIdentifier)
  }

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return appContext.vcardSourceStore.count
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier(CellReuseIdentifier, forIndexPath: indexPath) as UITableViewCell
    cell.textLabel?.text = getSource(at: indexPath.row).name
    return cell
  }

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let vc = VCardSourceDetailViewController(appContext: appContext, onIndex: indexPath.row) {
      self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
    }
    self.navigationController?.pushViewController(vc, animated: true)
  }

  private func getSource(at index: Int) -> VCardSource {
    return appContext.vcardSourceStore[index]
  }
}
