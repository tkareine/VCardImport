import UIKit

class VCardToolbar: UIView {
  let syncButton: UIButton!
  let backupButton: UIButton!
  let progressLabel: UILabel!
  let progressView: UIProgressView!
  let border: CALayer!

  override var frame: CGRect {
    get {
      return super.frame
    }

    set {
      super.frame = newValue
      if border != nil {
        border.frame = getBorderLayerRect(newValue)
      }
    }
  }

  override init() {
    super.init()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    syncButton = makeButton("Sync", align: .Left)
    backupButton = makeButton("Backup", align: .Right)
    progressLabel = makeProgressLabel()
    progressView = makeProgressView()
    border = makeBorderLayer(frame)

    addSubview(syncButton)
    addSubview(progressLabel)
    addSubview(progressView)
    addSubview(backupButton)
    layer.addSublayer(border)

    backgroundColor = UIColor.whiteColor()

    setupLayout()
  }

  required init(coder decoder: NSCoder) {
    fatalError("not implemented")
  }

  func beginProgress(text: String) {
    progressLabel.text = text
    progressView.setProgress(0.0, animated: false)

    UIView.animateWithDuration(
      0.5,
      delay: 0,
      options: .CurveEaseIn,
      animations: {
        self.progressLabel.alpha = 1.0
        self.progressView.alpha = 1.0
      },
      completion: nil)
  }

  func endProgress() {
    UIView.animateWithDuration(
      0.5,
      delay: 0,
      options: .CurveEaseOut,
      animations: {
        self.progressLabel.alpha = 0.0
        self.progressView.alpha = 0.0
      },
      completion: { _ in
        self.progressLabel.text = nil
        self.progressView.setProgress(0.0, animated: false)
      })
  }

  func inProgress(text: String, progress: Float) {
    progressLabel.text = text
    progressView.setProgress(progress, animated: true)
  }

  // MARK: Helpers

  private func makeButton(
    title: String,
    align labelAlignment: UIControlContentHorizontalAlignment)
    -> UIButton
  {
    let button = UIButton.buttonWithType(.System) as UIButton
    button.setTitle(title, forState: .Normal)
    if let label = button.titleLabel {
      label.font = label.font.fontWithSize(16.0)
    }
    button.contentHorizontalAlignment = labelAlignment
    return button
  }

  private func makeProgressLabel() -> UILabel {
    let label = UILabel()
    label.textAlignment = .Center
    label.adjustsFontSizeToFitWidth = true
    label.font = label.font.fontWithSize(14.0)
    label.minimumScaleFactor = 0.5
    label.alpha = 0.0
    return label
  }

  private func makeProgressView() -> UIProgressView {
    let view = UIProgressView(progressViewStyle: .Bar)
    view.alpha = 0.0
    return view
  }

  private func makeBorderLayer(frame: CGRect) -> CALayer {
    let layer = CALayer()
    layer.frame = getBorderLayerRect(frame)
    layer.backgroundColor = UIColor(white: 0.8, alpha: 1.0).CGColor
    return layer
  }

  private func getBorderLayerRect(frame: CGRect) -> CGRect {
    return CGRect(x: 0, y: 0, width: frame.size.width, height: 1)
  }

  private func setupLayout() {
    syncButton.setTranslatesAutoresizingMaskIntoConstraints(false)
    syncButton.setContentHuggingPriority(251, forAxis: .Horizontal)
    backupButton.setTranslatesAutoresizingMaskIntoConstraints(false)
    backupButton.setContentHuggingPriority(251, forAxis: .Horizontal)
    progressLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
    progressLabel.setContentCompressionResistancePriority(749, forAxis: .Horizontal)
    progressView.setTranslatesAutoresizingMaskIntoConstraints(false)

    let viewNamesToObjects = [
      "syncButton": syncButton,
      "backupButton": backupButton,
      "progressLabel": progressLabel,
      "progressView": progressView
    ]

    let constraintSyncButtonCenterY = NSLayoutConstraint(
      item: syncButton,
      attribute: .CenterY,
      relatedBy: .Equal,
      toItem: self,
      attribute: .CenterY,
      multiplier: 1,
      constant: 0)

    let constraintBackupButtonCenterY = NSLayoutConstraint(
      item: backupButton,
      attribute: .CenterY,
      relatedBy: .Equal,
      toItem: self,
      attribute: .CenterY,
      multiplier: 1,
      constant: 0)

    let constraintButtonsEqualWidth = NSLayoutConstraint(
      item: syncButton,
      attribute: .Width,
      relatedBy: .Equal,
      toItem: backupButton,
      attribute: .Width,
      multiplier: 1,
      constant: 0)

    let constraintHorizontalLayout = NSLayoutConstraint.constraintsWithVisualFormat(
      "H:|-[syncButton(>=50)]-[progressLabel]-[backupButton(>=50)]-|",
      options: nil,
      metrics: nil,
      views: viewNamesToObjects)

    let constraintProgressViewBetweenButtons = NSLayoutConstraint.constraintsWithVisualFormat(
      "H:[syncButton]-[progressView]-[backupButton]",
      options: nil,
      metrics: nil,
      views: viewNamesToObjects)

    let constraintProgressLabelAndViewLayout = NSLayoutConstraint.constraintsWithVisualFormat(
      "V:|-2-[progressLabel]-2-[progressView]-20-|",
      options: nil,
      metrics: nil,
      views: viewNamesToObjects)

    addConstraint(constraintSyncButtonCenterY)
    addConstraint(constraintBackupButtonCenterY)
    addConstraint(constraintButtonsEqualWidth)
    addConstraints(constraintHorizontalLayout)
    addConstraints(constraintProgressViewBetweenButtons)
    addConstraints(constraintProgressLabelAndViewLayout)
  }
}
