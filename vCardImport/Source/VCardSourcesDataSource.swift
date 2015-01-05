import UIKit

class VCardSourcesDataSource: NSObject, UITableViewDataSource {
  private let vcardSourceStore: VCardSourceStore
  private var vcardSourceIdsByTableRows: [Int: String] = [:]
  private var tableRowsByVCardSourceIds: [String: Int] = [:]

  init(vcardSourceStore: VCardSourceStore) {
    self.vcardSourceStore = vcardSourceStore

    for (index, sourceId) in enumerate(vcardSourceStore.sourceIds) {
      vcardSourceIdsByTableRows[index] = sourceId
      tableRowsByVCardSourceIds[sourceId] = index
    }
  }

  var hasEnabledVCardSources: Bool {
    return vcardSourceStore.countEnabled > 0
  }

  var enabledVCardSources: [VCardSource] {
    return vcardSourceStore.filterEnabled
  }

  func setVCardSource(source: VCardSource, status: String) {
    let s = source.withSyncStatus(status, at: NSDate())
    vcardSourceStore[s.id] = s
  }

  func saveVCardSource(source: VCardSource) {
    vcardSourceStore[source.id] = source
    vcardSourceStore.save()
  }

  func vCardSourceForRow(row: Int) -> VCardSource {
    return vcardSourceStore[vcardSourceIdsByTableRows[row]!]
  }

  func rowForVCardSource(source: VCardSource) -> Int {
    return tableRowsByVCardSourceIds[source.id]!
  }

  // MARK: data source delegate

  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return vcardSourceStore.countAll
  }

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier(UIConfig.SourcesCellReuseIdentifier, forIndexPath: indexPath) as VCardSourceCell

    func setDetailText(text: String, color: UIColor) {
      if let dt = cell.detailTextLabel {
        dt.text = text
        dt.textColor = color
      }
    }

    let vcardSourceId = vcardSourceIdsByTableRows[indexPath.row]!
    let source = vcardSourceStore[vcardSourceId]

    cell.textLabel?.text = source.name

    if let date = source.lastSyncedAt {
      let status = source.lastSyncStatus ?? ""
      setDetailText("\(date) - \(status)", UIColor.blackColor())
    } else {
      setDetailText("not synced", UIColor.grayColor())
    }

    return cell
  }
}
