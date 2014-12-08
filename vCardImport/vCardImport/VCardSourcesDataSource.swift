import UIKit

class VCardSourcesDataSource: NSObject, UITableViewDataSource {
  private let vcardSourceStore: VCardSourceStore

  init(vcardSourceStore: VCardSourceStore) {
    self.vcardSourceStore = vcardSourceStore
  }

  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return vcardSourceStore.count
  }

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier(UIConfig.SourcesCellReuseIdentifier, forIndexPath: indexPath) as UITableViewCell
    cell.textLabel?.text = vcardSourceStore[indexPath.row].name
    return cell
  }
}
