import Foundation

class VCardSource: NSObject, NSCoding {
  let name: String
  let connection: Connection

  init(name: String, connection: Connection) {
    self.name = name
    self.connection = connection
  }

  required init(coder decoder: NSCoder) {
    name = decoder.decodeObjectForKey("name") as String
    connection = decoder.decodeObjectForKey("connection") as Connection
  }

  func encodeWithCoder(coder: NSCoder) {
    coder.encodeObject(name, forKey: "name")
    coder.encodeObject(connection, forKey: "connection")
  }

  class Connection: NSObject, NSCoding {
    let url: NSURL

    init(url: NSURL) {
      self.url = url
    }

    required init(coder decoder: NSCoder) {
      url = NSURL(string: decoder.decodeObjectForKey("url") as String)!
    }

    func encodeWithCoder(coder: NSCoder) {
      coder.encodeObject(url.absoluteString, forKey: "url")
    }
  }
}
