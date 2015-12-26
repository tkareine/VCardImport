import UIKit

extension UIFont {
  static func fontForBodyStyle() -> UIFont {
    return UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
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

  private func traited(traits: [UIFontDescriptorSymbolicTraits]) -> UIFont {
    let descriptor = fontDescriptor()
      .fontDescriptorWithSymbolicTraits(UIFontDescriptorSymbolicTraits(traits))
    return UIFont(descriptor: descriptor, size: 0)
  }
}
