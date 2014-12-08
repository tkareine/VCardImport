import UIKit

class VCardSourcesViewController: UITableViewController {
  convenience override init() {
    self.init(style: UITableViewStyle.Plain)
  }

  override init(style: UITableViewStyle) {
    super.init(style: style)
    self.navigationItem.title = "vCard Import"
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return VCardSourceStore.sharedStore.sources.count
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("UITableViewCell", forIndexPath: indexPath) as UITableViewCell
    let source = VCardSourceStore.sharedStore.sources[indexPath.row]
    cell.textLabel?.text = source.name
    return cell
  }

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let vc = VCardSourceDetailViewController()
    self.navigationController?.pushViewController(vc, animated: true)
  }
}
