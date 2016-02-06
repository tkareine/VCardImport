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
  static let DefaultMargin: Float = 15

  private let label: UILabel

  init(
    frame: CGRect,
    text: String,
    textColor: UIColor,
    textAlignment: NSTextAlignment,
    topMargin: Float = DefaultMargin,
    bottomMargin: Float = DefaultMargin)
  {
    self.label = makeLabel(
      text: text,
      textColor: textColor,
      textAlignment: textAlignment)

    super.init(frame: frame)

    addSubview(label)

    setupLayout(topMargin: topMargin, bottomMargin: bottomMargin)

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

  // MARK: Notification Handlers

  func resetFontSizes() {
    label.font = makeFont()
  }

  // MARK: Helpers

  private func setupLayout(topMargin topMargin: Float, bottomMargin: Float) {
    label.translatesAutoresizingMaskIntoConstraints = false

    let viewNamesToObjects = ["label": label]

    NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
      "H:|-margin-[label]-margin-|",
      options: [],
      metrics: [
        "margin": MultilineLabel.DefaultMargin
      ],
      views: viewNamesToObjects))

    NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
      "V:|-topMargin-[label]-bottomMargin-|",
      options: [],
      metrics: [
        "topMargin": topMargin,
        "bottomMargin": bottomMargin
      ],
      views: viewNamesToObjects))
  }
}
