private func traited(
  font: UIFont,
  traits: [UIFontDescriptorSymbolicTraits])
  -> UIFont
{
  let descriptor = font
    .fontDescriptor()
    .fontDescriptorWithSymbolicTraits(UIFontDescriptorSymbolicTraits(traits))
  return UIFont(descriptor: descriptor, size: 0)
}

struct Fonts {
  static func bodyFont() -> UIFont {
    return UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
  }

  static func sizeAdjusted(font: UIFont, by sizeAdjustment: CGFloat) -> UIFont {
    return font.fontWithSize(font.pointSize + sizeAdjustment)
  }

  static func bold(font: UIFont) -> UIFont {
    return traited(font, traits: [.TraitBold])
  }

  static func normal(font: UIFont) -> UIFont {
    return traited(font, traits: [])
  }
}
