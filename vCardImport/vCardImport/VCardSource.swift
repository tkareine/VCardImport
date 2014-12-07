import Foundation

class VCardSource: NSCoding {
  var name: String
  var connection: Connection

  init(name: String, connection: Connection) {
    self.name = name
    self.connection = connection
  }

  required init(coder decoder: NSCoder) {
    self.name = decoder.decodeObjectForKey("name") as String
    self.connection = decoder.decodeObjectForKey("connection") as Connection
  }

  func encodeWithCoder(coder: NSCoder) {
    coder.encodeObject(name, forKey: "name")
    coder.encodeObject(connection, forKey: "connection")
  }

  class Connection: NSCoding {
    var url: String

    init(url: String) {
      self.url = url
    }

    required init(coder decoder: NSCoder) {
      self.url = decoder.decodeObjectForKey("url") as String
    }

    func encodeWithCoder(coder: NSCoder) {
      coder.encodeObject(url, forKey: "url")
    }
  }
}
