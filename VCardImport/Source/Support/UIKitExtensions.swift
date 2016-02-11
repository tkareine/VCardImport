import UIKit

extension UIFont {
  static func fontForBodyStyle() -> UIFont {
    return fontForStyle(UIFontTextStyleBody)
  }

  static func fontForHeadlineStyle() -> UIFont {
    return fontForStyle(UIFontTextStyleHeadline)
  }

  func sizeAdjusted(sizeAdjustment: CGFloat) -> UIFont {
    return fontWithSize(pointSize + sizeAdjustment)
  }

  func bolded() -> UIFont {
    return traited([.TraitBold])
  }

  func normalized() -> UIFont {
    return traited([])
  }

  private static func fontForStyle(styleName: String) -> UIFont {
    return UIFont.preferredFontForTextStyle(styleName)
  }

  private func traited(traits: [UIFontDescriptorSymbolicTraits]) -> UIFont {
    let descriptor = fontDescriptor()
      .fontDescriptorWithSymbolicTraits(UIFontDescriptorSymbolicTraits(traits))
    return UIFont(descriptor: descriptor, size: 0)
  }
}
