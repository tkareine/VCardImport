import UIKit

class VCardSourceCell: UITableViewCell {
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: .Subtitle, reuseIdentifier: Config.UI.SourcesCellReuseIdentifier)
    accessoryType = .DisclosureIndicator
    if let label = detailTextLabel {
      label.numberOfLines = 2
      label.lineBreakMode = .ByWordWrapping
      label.font = UIFont.systemFontOfSize(12.0)
    }
  }

  required init(coder decoder: NSCoder) {
    fatalError("not implemented")
  }
}
