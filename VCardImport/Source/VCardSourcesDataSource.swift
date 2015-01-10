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

  // MARK: Our Data Source API

  var hasVCardSources: Bool {
    return vcardSourceStore.countAll > 0
  }

  var hasEnabledVCardSources: Bool {
    return vcardSourceStore.countEnabled > 0
  }

  var enabledVCardSources: [VCardSource] {
    return vcardSourceStore.filterEnabled
  }

  func setVCardSourceFailureStatus(source: VCardSource, error: NSError) {
    setVCardSourceStatus(error.localizedDescription, to: source)
  }

  func setVCardSourceSuccessStatus(source: VCardSource, changes: (Int, Int)) {
    var status: String

    let (additions, updates) = changes
    if additions == 0 && updates == 0 {
      status = "Nothing to change"
    } else {
      var additionsStatus: String
      switch additions {
      case 0:
        additionsStatus = "No additions"
      case 1:
        additionsStatus = "1 addition"
      default:
        additionsStatus = "\(additions) additions"
      }

      var updatesStatus: String
      switch updates {
      case 0:
        updatesStatus = "no updates"
      case 1:
        updatesStatus = "1 update"
      default:
        updatesStatus = "\(updates) updates"
      }

      status = "\(additionsStatus), \(updatesStatus)"
    }

    setVCardSourceStatus(status, to: source)
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

  // MARK: Table View Data Source Delegate

  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return vcardSourceStore.countAll
  }

  func tableView(
    tableView: UITableView,
    cellForRowAtIndexPath indexPath: NSIndexPath)
    -> UITableViewCell
  {
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
      setDetailText("\(date.localeMediumString) - \(status)", UIColor.blackColor())
    } else {
      setDetailText("Not synced", UIColor.grayColor())
    }

    return cell
  }

  func tableView(
    tableView: UITableView,
    commitEditingStyle editingStyle: UITableViewCellEditingStyle,
    forRowAtIndexPath indexPath: NSIndexPath)
  {
    if (editingStyle == .Delete) {
      // TODO
    }
  }

  // MARK: Helpers

  private func setVCardSourceStatus(status: String, to source: VCardSource) {
    let s = source.withSyncStatus(status, at: NSDate())
    vcardSourceStore[s.id] = s
    vcardSourceStore.save()
  }
}
