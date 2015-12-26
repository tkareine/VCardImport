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
      selector: "resetFontSizes",
      name: UIContentSizeCategoryDidChangeNotification,
      object: nil)

    resetFontSizes()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }

  var on: Bool {
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

    let viewNamesToObjects = [
      "label": label,
      "switch": theSwitch
    ]

    contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
      "H:|-[label]-[switch]-|",
      options: [],
      metrics: nil,
      views: viewNamesToObjects))

    contentView.addConstraint(NSLayoutConstraint(
      item: label,
      attribute: .CenterY,
      relatedBy: .Equal,
      toItem: contentView,
      attribute: .CenterY,
      multiplier: 1,
      constant: 0))

    contentView.addConstraint(NSLayoutConstraint(
      item: theSwitch,
      attribute: .CenterY,
      relatedBy: .Equal,
      toItem: contentView,
      attribute: .CenterY,
      multiplier: 1,
      constant: 0))
  }
}
