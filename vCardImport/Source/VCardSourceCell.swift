import UIKit

class VCardSourceCell: UITableViewCell {
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: .Subtitle, reuseIdentifier: UIConfig.SourcesCellReuseIdentifier)
  }

  required init(coder decoder: NSCoder) {
    fatalError("state restoration not supported")
  }
}
