import UIKit

private func makeFont() -> UIFont {
  return UIFont.fontForBodyStyle().sizeAdjusted(-4)
}

private func makeLabel(text: String) -> UILabel {
  let label = UILabel()
  label.text = text
  label.font = makeFont()
  label.textAlignment = .Center
  label.lineBreakMode = .ByWordWrapping
  label.numberOfLines = 0
  return label
}

class MultilineLabel: UIView {
  private let label: UILabel

  init(frame: CGRect, labelText: String) {
    label = makeLabel(labelText)

    super.init(frame: frame)

    addSubview(label)

    setupLayout()

    NSNotificationCenter.defaultCenter().addObserver(
      self,
      selector: "resetFontSizes",
      name: UIContentSizeCategoryDidChangeNotification,
      object: nil)
  }

  required init?(coder decoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }

  // MARK: Laying out Subviews

  override func layoutSubviews() {
    super.layoutSubviews()
    label.preferredMaxLayoutWidth = label.frame.size.width
    super.layoutSubviews()
  }

  // MARK: Notification Handlers

  func resetFontSizes() {
    label.font = makeFont()
  }

  // MARK: Helpers

  private func setupLayout() {
    label.translatesAutoresizingMaskIntoConstraints = false

    let viewNamesToObjects = ["label": label]

    NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
      "H:|-[label]-|",
      options: [],
      metrics: nil,
      views: viewNamesToObjects))

    NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
      "V:|-15-[label]-15-|",
      options: [],
      metrics: nil,
      views: viewNamesToObjects))
  }
}
