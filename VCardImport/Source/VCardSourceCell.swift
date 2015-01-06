import UIKit

class VCardSourceCell: UITableViewCell {
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: .Subtitle, reuseIdentifier: UIConfig.SourcesCellReuseIdentifier)
    accessoryType = .DisclosureIndicator
  }

  required init(coder decoder: NSCoder) {
    fatalError("not implemented")
  }
}
