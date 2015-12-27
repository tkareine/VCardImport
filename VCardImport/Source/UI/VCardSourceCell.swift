import UIKit

class VCardSourceCell: UITableViewCell {
  @IBOutlet weak var headerLabel: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var iconLabel: UILabel!

  @IBOutlet weak var headerLabelLeadingConstraint: NSLayoutConstraint!
  @IBOutlet weak var descriptionLabelLeadingConstraint: NSLayoutConstraint!

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

  func setContentLeadingSpace(spacing: CGFloat) {
    headerLabelLeadingConstraint.constant = spacing
    descriptionLabelLeadingConstraint.constant = spacing
  }

  // MARK: Notification Handlers

  func resetFontSizes() {
    let font = UIFont.fontForBodyStyle()
    headerLabel.font = font
    iconLabel.font = font
    descriptionLabel.font = font.sizeAdjusted(-4)
  }
}
