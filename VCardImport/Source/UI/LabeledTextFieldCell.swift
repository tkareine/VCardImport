import UIKit

private let FontSizeAdjustment: CGFloat = -2

private func makeFont() -> UIFont {
  return UIFont.fontForBodyStyle().sizeAdjusted(FontSizeAdjustment)
}

private func fontPointSize() -> CGFloat {
  return UIFont.fontForBodyStyle().pointSize + FontSizeAdjustment
}

private func makeLabel(text: String) -> UILabel {
  let label = UILabel()
  label.font = makeFont()
  label.textAlignment = .Left
  label.text = text
  return label
}

private func makeTextField(
  text: String,
  autocapitalizationType: UITextAutocapitalizationType,
  autocorrectionType: UITextAutocorrectionType,
  spellCheckingType: UITextSpellCheckingType,
  isSecure: Bool,
  delegate: UITextFieldDelegate?)
  -> UITextField
{
  let textField = UITextField()
  textField.font = makeFont()
  textField.autocapitalizationType = autocapitalizationType
  textField.autocorrectionType = autocorrectionType
  textField.spellCheckingType = spellCheckingType
  textField.textAlignment = .Right
  textField.clearButtonMode = .WhileEditing
  textField.text = text
  textField.secureTextEntry = isSecure
  textField.delegate = delegate
  return textField
}

class LabeledTextFieldCell: UITableViewCell {
  private let label: UILabel
  private let textField: UITextField
  private let textFieldDelegate: UITextFieldDelegate?

  init(
    label labelText: String,
    value valueText: String,
    autocapitalizationType: UITextAutocapitalizationType = .None,
    autocorrectionType: UITextAutocorrectionType = .No,
    spellCheckingType: UITextSpellCheckingType = .No,
    isSecure: Bool = false,
    textFieldDelegate: UITextFieldDelegate? = nil)
  {
    label = makeLabel(labelText)

    self.textFieldDelegate = textFieldDelegate

    textField = makeTextField(
      valueText,
      autocapitalizationType: autocapitalizationType,
      autocorrectionType: autocorrectionType,
      spellCheckingType: spellCheckingType,
      isSecure: isSecure,
      delegate: self.textFieldDelegate)

    super.init(style: .Default, reuseIdentifier: nil)

    contentView.addSubview(label)
    contentView.addSubview(textField)

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

  var currentText: String {
    return textField.text!
  }

  func highlightLabel(isHighlighted: Bool) {
    label.textColor = isHighlighted ? UIColor.redColor() : UIColor.blackColor()
    label.font = isHighlighted ? label.font.bolded() : label.font.normalized()
  }

  // MARK: Notification Handlers

  func resetFontSizes() {
    let fontSize = fontPointSize()
    label.font = label.font.fontWithSize(fontSize)
    textField.font = textField.font!.fontWithSize(fontSize)
  }

  // MARK: Helpers

  private func setupLayout() {
    label.translatesAutoresizingMaskIntoConstraints = false
    textField.translatesAutoresizingMaskIntoConstraints = false

    label.setContentHuggingPriority(251, forAxis: .Horizontal)

    let viewNamesToObjects = [
      "label": label,
      "textField": textField
    ]

    contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
      "H:|-[label]-[textField]-|",
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
      item: textField,
      attribute: .CenterY,
      relatedBy: .Equal,
      toItem: contentView,
      attribute: .CenterY,
      multiplier: 1,
      constant: 0))
  }
}
