import UIKit

class VCardSourcesDataSource: NSObject, UITableViewDataSource {
  private let vcardSourceStore: VCardSourceStore

  init(vcardSourceStore: VCardSourceStore) {
    self.vcardSourceStore = vcardSourceStore
  }

  // MARK: Our Data Source API

  var hasVCardSources: Bool {
    return !vcardSourceStore.isEmpty
  }

  var hasEnabledVCardSources: Bool {
    return vcardSourceStore.countEnabled > 0
  }

  var enabledVCardSources: [VCardSource] {
    return vcardSourceStore.filterEnabled
  }

  func setVCardSourceFailureStatus(source: VCardSource, error: NSError) {
    setVCardSourceStatus(
      false,
      message: error.localizedDescription,
      modifiedHeaderStamp: nil,
      to: source)
  }

  func setVCardSourceSuccessStatus(
    source: VCardSource,
    changes: (Int, Int),
    modifiedHeaderStamp: ModifiedHeaderStamp?)
  {
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

    setVCardSourceStatus(
      true,
      message: status,
      modifiedHeaderStamp: modifiedHeaderStamp,
      to: source)
  }

  func saveVCardSource(source: VCardSource) {
    vcardSourceStore.update(source)
    vcardSourceStore.save()
  }

  func vCardSourceForRow(row: Int) -> VCardSource {
    return vcardSourceStore[row]
  }

  func rowForVCardSource(source: VCardSource) -> Int {
    return vcardSourceStore.indexOf(source)!
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
    let cell = tableView.dequeueReusableCellWithIdentifier(Config.UI.SourcesCellReuseIdentifier, forIndexPath: indexPath) as VCardSourceCell

    func setDetailText(text: String, color: UIColor) {
      if let dt = cell.detailTextLabel {
        dt.text = text
        dt.textColor = color
      }
    }

    let source = vcardSourceStore[indexPath.row]

    if let textLabel = cell.textLabel {
      textLabel.text = source.name
      textLabel.textColor = source.isEnabled ? Config.UI.CellTextColorEnabled : Config.UI.CellTextColorDisabled
    }

    if let importResult = source.lastImportResult {
      let warningStr = importResult.isSuccess ? "" : "⚠️ "
      let message = importResult.message
      let dateStr = importResult.importedAt.localeMediumString
      let color = source.isEnabled ? Config.UI.CellTextColorEnabled : Config.UI.CellTextColorDisabled
      setDetailText("\(warningStr)\(dateStr) - \(message)", color)
    } else {
      setDetailText("Not imported yet", Config.UI.CellTextColorDisabled)
    }

    return cell
  }

  func tableView(
    tableView: UITableView,
    commitEditingStyle editingStyle: UITableViewCellEditingStyle,
    forRowAtIndexPath indexPath: NSIndexPath)
  {
    if (editingStyle == .Delete) {
      removeVCardSource(indexPath.row)
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:.Fade)
    }
  }

  func tableView(
    tableView: UITableView,
    moveRowAtIndexPath sourceIndexPath: NSIndexPath,
    toIndexPath destinationIndexPath: NSIndexPath)
  {
    vcardSourceStore.move(fromIndex: sourceIndexPath.row, toIndex: destinationIndexPath.row)
    vcardSourceStore.save()
  }

  // MARK: Helpers

  private func setVCardSourceStatus(
    isSuccess: Bool,
    message: String,
    modifiedHeaderStamp: ModifiedHeaderStamp?,
    to source: VCardSource)
  {
    let s = source.withLastImportResult(
      isSuccess,
      message: message,
      at: NSDate(),
      modifiedHeaderStamp: modifiedHeaderStamp)
    vcardSourceStore.update(s)
    vcardSourceStore.save()
  }

  private func removeVCardSource(row: Int) {
    vcardSourceStore.remove(row)
    vcardSourceStore.save()
  }
}
