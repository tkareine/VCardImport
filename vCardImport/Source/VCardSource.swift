import Foundation

class VCardSource {
  let name: String
  let connection: Connection
  let isEnabled: Bool
  let id: String

  init(name: String, connection: Connection, isEnabled: Bool, id: String = NSUUID().UUIDString) {
    self.name = name
    self.connection = connection
    self.isEnabled = isEnabled
    self.id = id
  }

  class Connection {
    let url: NSURL

    init(url: NSURL) {
      self.url = url
    }
  }
}

extension VCardSource: DictionaryConvertible {
  typealias DictionaryType = VCardSource

  func toDictionary() -> [String: AnyObject] {
    return [
      "name": name,
      "connection": connection.toDictionary(),
      "isEnabled": isEnabled,
      "id": id
    ]
  }

  class func fromDictionary(dictionary: [String: AnyObject]) -> DictionaryType {
    return DictionaryType(
      name: dictionary["name"] as String,
      connection: Connection.fromDictionary(dictionary["connection"] as [String: AnyObject]),
      isEnabled: dictionary["isEnabled"] as Bool,
      id: dictionary["id"] as String)
  }
}

extension VCardSource.Connection: DictionaryConvertible {
  typealias DictionaryType = VCardSource.Connection

  func toDictionary() -> [String: AnyObject] {
    return ["url": url.absoluteString!]
  }

  class func fromDictionary(dictionary: [String : AnyObject]) -> DictionaryType {
    return DictionaryType(url: NSURL(string: dictionary["url"] as String)!)
  }
}
