import Foundation

struct VCardSource {
  let name: String
  let connection: Connection
  let isEnabled: Bool
  let id: String
  let lastImportStatus: ImportStatus?

  init(
    name: String,
    connection: Connection,
    isEnabled: Bool,
    id: String = NSUUID().UUIDString,
    lastImportStatus: ImportStatus? = nil)
  {
    self.name = name
    self.connection = connection
    self.isEnabled = isEnabled
    self.id = id
    self.lastImportStatus = lastImportStatus
  }

  static func emptySource() -> VCardSource {
    return VCardSource(
      name: "",
      connection: VCardSource.Connection(url: NSURL(string: "")!),
      isEnabled: true)
  }

  func withName(
    name: String,
    connection: Connection,
    isEnabled: Bool)
    -> VCardSource
  {
    return VCardSource(
      name: name,
      connection: connection,
      isEnabled: isEnabled,
      id: id,
      lastImportStatus: lastImportStatus)
  }

  func withLastImportStatus(
    isSuccess: Bool,
    message: String,
    at importedAt: NSDate)
    -> VCardSource
  {
    return VCardSource(
      name: name,
      connection: connection,
      isEnabled: isEnabled,
      id: id,
      lastImportStatus: VCardSource.ImportStatus(
        isSuccess: isSuccess,
        message: message,
        importedAt: importedAt))
  }

  struct Connection {
    let url: NSURL
  }

  struct ImportStatus {
    let isSuccess: Bool
    let message: String
    let importedAt: NSDate
  }
}

extension VCardSource: DictionaryConvertible {
  typealias DictionaryType = VCardSource

  func toDictionary() -> [String: AnyObject] {
    var dict: [String: AnyObject] = [
      "name": name,
      "connection": connection.toDictionary(),
      "isEnabled": isEnabled,
      "id": id
    ]
    if let importStatus = lastImportStatus {
      dict["lastImportStatus"] = importStatus.toDictionary()
    }
    return dict
  }

  static func fromDictionary(dictionary: [String: AnyObject]) -> DictionaryType {
    var lastImportStatus: ImportStatus?
    if let importStatus = dictionary["lastImportStatus"] as? [String: AnyObject] {
       lastImportStatus = VCardSource.ImportStatus.fromDictionary(importStatus)
    }

    return DictionaryType(
      name: dictionary["name"] as String!,
      connection: Connection.fromDictionary(dictionary["connection"] as [String: AnyObject]!),
      isEnabled: dictionary["isEnabled"] as Bool!,
      id: dictionary["id"] as String!,
      lastImportStatus: lastImportStatus)
  }
}

extension VCardSource.Connection: DictionaryConvertible {
  typealias DictionaryType = VCardSource.Connection

  func toDictionary() -> [String: AnyObject] {
    return ["url": url.absoluteString!]
  }

  static func fromDictionary(dictionary: [String: AnyObject]) -> DictionaryType {
    return DictionaryType(url: NSURL(string: dictionary["url"] as String)!)
  }
}

extension VCardSource.ImportStatus: DictionaryConvertible {
  typealias DictionaryType = VCardSource.ImportStatus

  func toDictionary() -> [String: AnyObject] {
    return [
      "isSuccess": isSuccess,
      "message": message,
      "importedAt": importedAt.ISOString
    ]
  }

  static func fromDictionary(dictionary: [String: AnyObject]) -> DictionaryType {
    return DictionaryType(
      isSuccess: dictionary["isSuccess"] as Bool,
      message: dictionary["message"] as String,
      importedAt: NSDate.dateFromISOString(dictionary["importedAt"] as String)!)
  }
}
