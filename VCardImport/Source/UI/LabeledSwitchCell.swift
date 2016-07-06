import UIKit

private func makeFont() -> UIFont {
  return UIFont.fontForBodyStyle().sizeAdjusted(-2)
}

private func makeLabel(text: String) -> UILabel {
  let label = UILabel()
  label.font = makeFont()
  label.textAlignment = .Left
  label.text = text
  return label
}

private func makeSwitch(isEnabled: Bool) -> UISwitch {
  let swi: UISwitch = UISwitch()
  swi.on = isEnabled
  return swi
}

class LabeledSwitchCell: UITableViewCell {
  private let label: UILabel
  private let theSwitch: UISwitch

  init(label labelText: String, isEnabled: Bool) {
    label = makeLabel(labelText)
    theSwitch = makeSwitch(isEnabled)

    super.init(style: .Default, reuseIdentifier: nil)

    contentView.addSubview(label)
    contentView.addSubview(theSwitch)

    setupLayout()

    NSNotificationCenter.defaultCenter().addObserver(
      self,
      selector: #selector(LabeledSwitchCell.resetFontSizes),
      name: UIContentSizeCategoryDidChangeNotification,
      object: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }

  var switchOn: Bool {
    return theSwitch.on
  }

  // MARK: Notification Handlers

  func resetFontSizes() {
    label.font = makeFont()
  }

  // MARK: Helpers

  private func setupLayout() {
    label.translatesAutoresizingMaskIntoConstraints = false
    theSwitch.translatesAutoresizingMaskIntoConstraints = false

    theSwitch.setContentHuggingPriority(251, forAxis: .Horizontal)
    theSwitch.setContentCompressionResistancePriority(751, forAxis: .Horizontal)

    NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
      "H:|-[label]-[switch]-|",
      options: [],
      metrics: nil,
      views: [
        "label": label,
        "switch": theSwitch
      ]))

    NSLayoutConstraint(
      item: label,
      attribute: .Top,
      relatedBy: .Equal,
      toItem: contentView,
      attribute: .TopMargin,
      multiplier: 1,
      constant: 0).active = true

    NSLayoutConstraint(
      item: label,
      attribute: .Bottom,
      relatedBy: .Equal,
      toItem: contentView,
      attribute: .BottomMargin,
      multiplier: 1,
      constant: 0).active = true

    NSLayoutConstraint(
      item: theSwitch,
      attribute: .CenterY,
      relatedBy: .Equal,
      toItem: contentView,
      attribute: .CenterY,
      multiplier: 1,
      constant: 0).active = true
  }
}
