import UIKit

class VCardSourceCell: UITableViewCell {
  @IBOutlet weak var headerLabel: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var iconLabel: UILabel!

  // MARK: View Life Cycle

  override func awakeFromNib() {
    NSNotificationCenter.defaultCenter().addObserver(
      self,
      selector: "resetFontSizes",
      name: UIContentSizeCategoryDidChangeNotification,
      object: nil)

    resetFontSizes()
  }

  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }

  // MARK: Helpers

  func setContents(source: VCardSource) {
    headerLabel.text = source.name
    headerLabel.textColor = source.isEnabled
      ? Config.UI.TableCellHeaderTextColor
      : Config.UI.TableCellDisabledTextColor

    descriptionLabel.textColor = source.isEnabled
      ? Config.UI.TableCellDescriptionTextColor
      : Config.UI.TableCellDisabledTextColor

    if let res = source.lastImportResult {
      descriptionLabel.text = "\(res.importedAt.localeMediumString) - \(res.message)"
      iconLabel.text = res.isSuccess ? nil : "⚠️"
    } else {
      descriptionLabel.text = "Not imported yet"
      iconLabel.text = nil
    }
  }

  func resetFontSizes() {
    let bodyFont = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
    headerLabel.font = bodyFont
    iconLabel.font = bodyFont
    descriptionLabel.font = UIFont.systemFontOfSize(bodyFont.pointSize - 4)
  }
}
