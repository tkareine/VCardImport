import UIKit

private func makeFont() -> UIFont {
  return UIFont.fontForBodyStyle().sizeAdjusted(-4)
}

private func makeLabel() -> UILabel {
  let label = UILabel()
  label.font = makeFont()
  label.textAlignment = .Center
  label.alpha = 0
  return label
}

class LabeledActivityIndicator: UIView {
  private let label: UILabel
  private let activityIndicator: UIActivityIndicatorView

  override init(frame: CGRect) {
    label = makeLabel()
    activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)

    super.init(frame: frame)

    addSubview(label)
    addSubview(activityIndicator)

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

  func start(text: String) {
    label.text = text

    UIView.animateWithDuration(
      Config.UI.AnimationDurationFadeMessage,  // TODO: Rename const
      delay: 0,
      options: .CurveEaseIn,
      animations: { [unowned self] in
        self.label.alpha = 1
      },
      completion: nil)

    activityIndicator.startAnimating()
  }

  func stop(text: String, fadeOut: Bool = false) {
    label.text = text
    activityIndicator.stopAnimating()

    if fadeOut {
      UIView.animateWithDuration(
        Config.UI.AnimationDurationFadeMessage,  // TODO: Rename const
        delay: Config.UI.AnimationDelayFadeOutMessage,  // TODO: Rename const
        options: .CurveEaseOut,
        animations: { [unowned self] in
          self.label.alpha = 0
        },
        completion: nil)
    }
  }

  // MARK: Notification Handlers

  func resetFontSizes() {
    label.font = makeFont()
  }

  // MARK: Helpers

  private func setupLayout() {
    label.translatesAutoresizingMaskIntoConstraints = false
    activityIndicator.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint(
      item: label,
      attribute: .CenterY,
      relatedBy: .Equal,
      toItem: self,
      attribute: .CenterY,
      multiplier: 1,
      constant: 0).active = true

    NSLayoutConstraint(
      item: label,
      attribute: .CenterX,
      relatedBy: .Equal,
      toItem: self,
      attribute: .CenterX,
      multiplier: 1,
      constant: 0).active = true

    NSLayoutConstraint(
      item: activityIndicator,
      attribute: .CenterY,
      relatedBy: .Equal,
      toItem: self,
      attribute: .CenterY,
      multiplier: 1,
      constant: 0).active = true

    NSLayoutConstraint(
      item: activityIndicator,
      attribute: .Trailing,
      relatedBy: .Equal,
      toItem: self,
      attribute: .TrailingMargin,
      multiplier: 1,
      constant: 0).active = true
  }
}
