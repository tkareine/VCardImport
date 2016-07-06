import UIKit

private let ActivityIndicatorSpace: CGFloat = 28

private func makeFont() -> UIFont {
  return UIFont.fontForBodyStyle().sizeAdjusted(-4)
}

private func makeLabel() -> UILabel {
  let label = UILabel()
  label.font = makeFont()
  label.textAlignment = .Center
  label.alpha = 0
  label.numberOfLines = 1
  return label
}

class LabeledActivityIndicator: UIView {
  private let label = makeLabel()
  private let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)

  private var labelLeadingLayoutConstraint: NSLayoutConstraint!
  private var labelTrailingLayoutConstraint: NSLayoutConstraint!
  private var activityIndicatorTrailingLayoutConstraint: NSLayoutConstraint!

  init() {
    super.init(frame: CGRect.zero)

    addSubview(label)
    addSubview(activityIndicator)

    setupLayout()

    NSNotificationCenter.defaultCenter().addObserver(
      self,
      selector: #selector(LabeledActivityIndicator.resetFontSizes),
      name: UIContentSizeCategoryDidChangeNotification,
      object: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }

  func setHorizontalMargins(leading leading: CGFloat, trailing: CGFloat) {
    labelLeadingLayoutConstraint.constant = leading + ActivityIndicatorSpace
    labelTrailingLayoutConstraint.constant = trailing + ActivityIndicatorSpace
    activityIndicatorTrailingLayoutConstraint.constant = trailing
  }

  func start(text: String) {
    label.text = text

    UIView.animateWithDuration(
      Config.UI.MessageFadeAnimationDuration,
      delay: 0,
      options: .CurveEaseIn,
      animations: { [unowned self] in
        self.label.alpha = 1
      },
      completion: nil)

    activityIndicator.startAnimating()
  }

  func stop(text: String? = nil, fadeOut: Bool = false) {
    label.text = text
    activityIndicator.stopAnimating()

    if fadeOut {
      UIView.animateWithDuration(
        Config.UI.MessageFadeAnimationDuration,
        delay: Config.UI.MessageFadeOutAnimationDelay,
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

    self.labelLeadingLayoutConstraint = NSLayoutConstraint(
      item: label,
      attribute: .Leading,
      relatedBy: .Equal,
      toItem: self,
      attribute: .Leading,
      multiplier: 1,
      constant: ActivityIndicatorSpace)
    self.labelLeadingLayoutConstraint.active = true

    self.labelTrailingLayoutConstraint = NSLayoutConstraint(
      item: self,
      attribute: .Trailing,
      relatedBy: .Equal,
      toItem: label,
      attribute: .Trailing,
      multiplier: 1,
      constant: ActivityIndicatorSpace)
    self.labelTrailingLayoutConstraint.active = true

    NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
      "V:|-[label(>=20)]-|",
      options: [],
      metrics: nil,
      views: ["label": label]))

    NSLayoutConstraint(
      item: activityIndicator,
      attribute: .CenterY,
      relatedBy: .Equal,
      toItem: self,
      attribute: .CenterY,
      multiplier: 1,
      constant: 0).active = true

    self.activityIndicatorTrailingLayoutConstraint = NSLayoutConstraint(
      item: self,
      attribute: .Trailing,
      relatedBy: .Equal,
      toItem: activityIndicator,
      attribute: .Trailing,
      multiplier: 1,
      constant: 0)
     self.activityIndicatorTrailingLayoutConstraint.active = true
  }
}
