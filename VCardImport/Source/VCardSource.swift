import Foundation

class VCardSource {
  let name: String
  let connection: Connection
  let isEnabled: Bool
  let id: String
  let lastSyncStatus: String?
  let lastSyncedAt: NSDate?

  init(
    name: String,
    connection: Connection,
    isEnabled: Bool,
    id: String = NSUUID().UUIDString,
    lastSyncStatus: String? = nil,
    lastSyncedAt: NSDate? = nil)
  {
    self.name = name
    self.connection = connection
    self.isEnabled = isEnabled
    self.id = id
    self.lastSyncStatus = lastSyncStatus
    self.lastSyncedAt = lastSyncedAt
  }

  convenience init() {
    self.init(
      name: "",
      connection: VCardSource.Connection(url: NSURL(string: "")!),
      isEnabled: true)
  }

  func withName(name: String, connection: Connection, isEnabled: Bool) -> VCardSource {
    return VCardSource(
      name: name,
      connection: connection,
      isEnabled: isEnabled,
      id: id,
      lastSyncStatus: lastSyncStatus,
      lastSyncedAt: lastSyncedAt)
  }

  func withSyncStatus(syncStatus: String, at syncedAt: NSDate) -> VCardSource {
    return VCardSource(
      name: name,
      connection: connection,
      isEnabled: isEnabled,
      id: id,
      lastSyncStatus: syncStatus,
      lastSyncedAt: syncedAt)
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

  private func asAnyObject<T: AnyObject>(t: T?) -> T! {
    if let tt = t {
      return tt
    } else {
      return nil
    }
  }

  func toDictionary() -> [String: AnyObject] {
    var dict: [String: AnyObject] = [
      "name": name,
      "connection": connection.toDictionary(),
      "isEnabled": isEnabled,
      "id": id
    ]
    if let ss = lastSyncStatus {
      dict["lastSyncStatus"] = ss
    }
    if let sa = lastSyncedAt {
      dict["lastSyncedAt"] = sa.ISOString
    }
    return dict
  }

  class func fromDictionary(dictionary: [String: AnyObject]) -> DictionaryType {
    var lastSyncedAt: NSDate?
    if let str = dictionary["lastSyncedAt"] as? String {
      lastSyncedAt = NSDate.dateFromISOString(str)
    }

    return DictionaryType(
      name: dictionary["name"] as String!,
      connection: Connection.fromDictionary(dictionary["connection"] as [String: AnyObject]!),
      isEnabled: dictionary["isEnabled"] as Bool!,
      id: dictionary["id"] as String!,
      lastSyncStatus: dictionary["lastSyncStatus"] as String?,
      lastSyncedAt: lastSyncedAt)
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
