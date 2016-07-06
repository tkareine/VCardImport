import UIKit

private func makeFont() -> UIFont {
  return UIFont.fontForBodyStyle().sizeAdjusted(-4)
}

private func makeLabel(
  text text: String,
  textColor: UIColor,
  textAlignment: NSTextAlignment)
  -> UILabel
{
  let label = UILabel()
  label.text = text
  label.textColor = textColor
  label.font = makeFont()
  label.textAlignment = textAlignment
  label.lineBreakMode = .ByWordWrapping
  label.numberOfLines = 0
  return label
}

class MultilineLabel: UIView {
  static let DefaultHorizontalMargin: CGFloat = 15
  static let DefaultVerticalMargin: CGFloat = 10

  private let label: UILabel

  private var leadingLayoutConstraint: NSLayoutConstraint!
  private var trailingLayoutConstraint: NSLayoutConstraint!

  init(
    text: String,
    textColor: UIColor,
    textAlignment: NSTextAlignment,
    topMargin: CGFloat = DefaultVerticalMargin,
    bottomMargin: CGFloat = DefaultVerticalMargin)
  {
    self.label = makeLabel(
      text: text,
      textColor: textColor,
      textAlignment: textAlignment)

    super.init(frame: CGRect.zero)

    addSubview(label)

    setupLayout(topMargin: topMargin, bottomMargin: bottomMargin)

    NSNotificationCenter.defaultCenter().addObserver(
      self,
      selector: #selector(MultilineLabel.resetFontSizes),
      name: UIContentSizeCategoryDidChangeNotification,
      object: nil)
  }

  required init?(coder decoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }

  func setHorizontalMargins(leading leading: CGFloat, trailing: CGFloat) {
    leadingLayoutConstraint.constant = leading
    trailingLayoutConstraint.constant = trailing
  }

  // MARK: Notification Handlers

  func resetFontSizes() {
    label.font = makeFont()
  }

  // MARK: Helpers

  private func setupLayout(topMargin topMargin: CGFloat, bottomMargin: CGFloat) {
    label.translatesAutoresizingMaskIntoConstraints = false

    self.leadingLayoutConstraint = NSLayoutConstraint(
      item: label,
      attribute: .Leading,
      relatedBy: .Equal,
      toItem: self,
      attribute: .Leading,
      multiplier: 1,
      constant: MultilineLabel.DefaultHorizontalMargin)
    self.leadingLayoutConstraint.active = true

    self.trailingLayoutConstraint = NSLayoutConstraint(
      item: self,
      attribute: .Trailing,
      relatedBy: .Equal,
      toItem: label,
      attribute: .Trailing,
      multiplier: 1,
      constant: MultilineLabel.DefaultHorizontalMargin)
    self.trailingLayoutConstraint.active = true

    NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
      "V:|-(topMargin)-[label]-(bottomMargin)-|",
      options: [],
      metrics: [
        "topMargin": topMargin,
        "bottomMargin": bottomMargin
      ],
      views: ["label": label]))
  }
}
