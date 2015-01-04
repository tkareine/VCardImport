import UIKit

class VCardSourcesDataSource: NSObject, UITableViewDataSource {
  private let vcardSourceStore: VCardSourceStore

  init(vcardSourceStore: VCardSourceStore) {
    self.vcardSourceStore = vcardSourceStore
  }

  // MARK: data source delegate

  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return vcardSourceStore.countAll
  }

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier(UIConfig.SourcesCellReuseIdentifier, forIndexPath: indexPath) as VCardSourceCell
    cell.textLabel?.text = vcardSourceStore[indexPath.row].name
    cell.detailTextLabel?.text = "not updated"
    return cell
  }
}
