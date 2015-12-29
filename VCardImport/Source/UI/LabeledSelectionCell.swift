import UIKit

private func makeFont() -> UIFont {
  return UIFont.fontForBodyStyle().sizeAdjusted(-2)
}

private func makeLabel(text: String, textAlignment: NSTextAlignment) -> UILabel {
  let label = UILabel()
  label.font = makeFont()
  label.textAlignment = textAlignment
  label.text = text
  return label
}

class LabeledSelectionCell<T>: UITableViewCell {
  private let label: UILabel
  private let selectionText: UILabel
  private var selectionData: T

  init(label labelText: String, selection: SelectionOption<T>) {
    label = makeLabel(labelText, textAlignment: .Left)
    selectionText = makeLabel(selection.description, textAlignment: .Right)
    selectionData = selection.data

    super.init(style: .Default, reuseIdentifier: nil)

    accessoryType = .DisclosureIndicator

    contentView.addSubview(label)
    contentView.addSubview(selectionText)

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

  var labelText: String {
    return label.text!
  }

  var selection: SelectionOption<T> {
    get {
      return SelectionOption(description: selectionText.text!, data: selectionData)
    }
    set {
      selectionText.text = newValue.description
      selectionData = newValue.data
    }
  }

  // MARK: Notification Handlers

  func resetFontSizes() {
    let font = makeFont()
    label.font = font
    selectionText.font = font
  }

  // MARK: Helpers

  private func setupLayout() {
    label.translatesAutoresizingMaskIntoConstraints = false
    selectionText.translatesAutoresizingMaskIntoConstraints = false

    label.setContentHuggingPriority(251, forAxis: .Horizontal)
    label.setContentCompressionResistancePriority(751, forAxis: .Horizontal)

    NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
      "H:|-[label]-[selection]-|",
      options: [],
      metrics: nil,
      views: [
        "label": label,
        "selection": selectionText
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
      item: selectionText,
      attribute: .Baseline,
      relatedBy: .Equal,
      toItem: label,
      attribute: .Baseline,
      multiplier: 1,
      constant: 0).active = true
  }
}
