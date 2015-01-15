import UIKit

class VCardSourceCell: UITableViewCell {
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: .Subtitle, reuseIdentifier: Config.UI.SourcesCellReuseIdentifier)
    accessoryType = .DisclosureIndicator
  }

  required init(coder decoder: NSCoder) {
    fatalError("not implemented")
  }
}
