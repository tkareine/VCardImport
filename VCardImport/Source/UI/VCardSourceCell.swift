import UIKit

private func makeFont(sizeAdjusted: CGFloat) -> UIFont {
  return UIFont.fontForBodyStyle().sizeAdjusted(sizeAdjusted)
}

private func makeLabel(
  textColor textColor: UIColor,
  sizeAdjustment: CGFloat = 0,
  textAlignment: NSTextAlignment = .Left,
  numberOfLines: Int = 1)
  -> UILabel
{
  let label = UILabel()
  label.font = makeFont(sizeAdjustment)
  label.textColor = textColor
  label.textAlignment = textAlignment
  label.numberOfLines = numberOfLines
  return label
}

class VCardSourceCell: UITableViewCell {
  private let headerLabel = makeLabel(
    textColor: Config.UI.TableCellHeaderTextColor)

  private let descriptionLabel = makeLabel(
    textColor: Config.UI.TableCellDescriptionTextColor,
    sizeAdjustment: -4,
    numberOfLines: 0)

  private let iconLabel = makeLabel(
    textColor: Config.UI.TableCellHeaderTextColor,
    textAlignment: .Right)

  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: .Default, reuseIdentifier: reuseIdentifier)

    accessoryType = .DisclosureIndicator

    contentView.addSubview(headerLabel)
    contentView.addSubview(descriptionLabel)
    contentView.addSubview(iconLabel)

    setupLayout()

    NSNotificationCenter.defaultCenter().addObserver(
      self,
      selector: #selector(VCardSourceCell.resetFontSizes),
      name: UIContentSizeCategoryDidChangeNotification,
      object: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
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
      descriptionLabel.text = "\(res.importedAt.describeRelativeDateToHuman().capitalized) - \(res.message)"
      iconLabel.text = res.isSuccess ? nil : "⚠️"  // no text saves space
      iconLabel.hidden = res.isSuccess
    } else {
      descriptionLabel.text = "Not imported yet"
      iconLabel.text = nil  // no text saves space
      iconLabel.hidden = true
    }
  }

  // MARK: Notification Handlers

  func resetFontSizes() {
    let font = UIFont.fontForBodyStyle()
    headerLabel.font = font
    descriptionLabel.font = font.sizeAdjusted(-4)
    iconLabel.font = font
  }

  // MARK: Helpers

  private func setupLayout() {
    headerLabel.translatesAutoresizingMaskIntoConstraints = false
    descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
    iconLabel.translatesAutoresizingMaskIntoConstraints = false

    headerLabel.setContentHuggingPriority(251, forAxis: .Vertical)
    headerLabel.setContentCompressionResistancePriority(751, forAxis: .Vertical)

    iconLabel.setContentHuggingPriority(251, forAxis: .Horizontal)
    iconLabel.setContentCompressionResistancePriority(751, forAxis: .Horizontal)

    let namesToViews = [
      "header": headerLabel,
      "description": descriptionLabel,
      "icon": iconLabel
    ]

    NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
      "V:|-[header]-[description]-|",
      options: [],
      metrics: nil,
      views: namesToViews))

    NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
      "H:|-[header]-[icon]-|",
      options: [],
      metrics: nil,
      views: namesToViews))

    NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
      "H:|-[description]-[icon]-|",
      options: [],
      metrics: nil,
      views: namesToViews))

    NSLayoutConstraint(
      item: iconLabel,
      attribute: .Trailing,
      relatedBy: .Equal,
      toItem: contentView,
      attribute: .TrailingMargin,
      multiplier: 1,
      constant: 0).active = true

    NSLayoutConstraint(
      item: iconLabel,
      attribute: .Top,
      relatedBy: .Equal,
      toItem: contentView,
      attribute: .TopMargin,
      multiplier: 1,
      constant: 0).active = true

    NSLayoutConstraint(
      item: iconLabel,
      attribute: .Bottom,
      relatedBy: .Equal,
      toItem: contentView,
      attribute: .BottomMargin,
      multiplier: 1,
      constant: 0).active = true
  }
}