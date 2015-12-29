import UIKit

private func makeFont(sizeAdjusted: CGFloat) -> UIFont {
  return UIFont.fontForBodyStyle().sizeAdjusted(sizeAdjusted)
}

private func makeLabel(
  textColor textColor: UIColor,
  sizeAdjustment: CGFloat,
  numberOfLines: Int)
  -> UILabel
{
  let label = UILabel()
  label.font = makeFont(sizeAdjustment)
  label.textColor = textColor
  label.textAlignment = .Left
  label.numberOfLines = numberOfLines
  return label
}

class SelectionOptionCell: UITableViewCell {
  private let headerLabel = makeLabel(
    textColor: Config.UI.TableCellHeaderTextColor,
    sizeAdjustment: -2,
    numberOfLines: 1)

  private let descriptionLabel = makeLabel(
    textColor: Config.UI.TableCellDescriptionTextColor,
    sizeAdjustment: -4,
    numberOfLines: 0)

  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: .Default, reuseIdentifier: reuseIdentifier)

    contentView.addSubview(headerLabel)
    contentView.addSubview(descriptionLabel)

    setupLayout()

    NSNotificationCenter.defaultCenter().addObserver(
      self,
      selector: "resetFontSizes",
      name: UIContentSizeCategoryDidChangeNotification,
      object: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }

  var headerText: String? {
    get {
      return headerLabel.text
    }
    set {
      headerLabel.text = newValue
    }
  }

  var descriptionText: String? {
    get {
      return descriptionLabel.text
    }
    set {
      descriptionLabel.text = newValue
    }
  }

  // MARK: Notification Handlers

  func resetFontSizes() {
    let font = UIFont.fontForBodyStyle()
    headerLabel.font = font.sizeAdjusted(-2)
    descriptionLabel.font = font.sizeAdjusted(-4)
  }

  // MARK: Helpers

  private func setupLayout() {
    headerLabel.translatesAutoresizingMaskIntoConstraints = false
    descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
      "V:|-[header]-[description]-|",
      options: [],
      metrics: nil,
      views: [
        "header": headerLabel,
        "description": descriptionLabel
      ]))

    for view in [headerLabel, descriptionLabel] {
      NSLayoutConstraint(
        item: view,
        attribute: .Leading,
        relatedBy: .Equal,
        toItem: contentView,
        attribute: .LeadingMargin,
        multiplier: 1,
        constant: 0).active = true

      NSLayoutConstraint(
        item: view,
        attribute: .Trailing,
        relatedBy: .Equal,
        toItem: contentView,
        attribute: .TrailingMargin,
        multiplier: 1,
        constant: 0).active = true
    }
  }
}
