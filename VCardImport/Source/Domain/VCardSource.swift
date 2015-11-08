import Foundation

struct VCardSource {
  let name: String
  let connection: Connection
  let isEnabled: Bool
  let id: String
  let lastImportResult: ImportResult?

  init(
    name: String,
    connection: Connection,
    isEnabled: Bool,
    id: String = NSUUID().UUIDString,
    lastImportResult: ImportResult? = nil)
  {
    self.name = name
    self.connection = connection
    self.isEnabled = isEnabled
    self.id = id
    self.lastImportResult = lastImportResult
  }

  static func empty() -> VCardSource {
    return self.init(
      name: "",
      connection: Connection.empty(),
      isEnabled: true)
  }

  func with(
    name name: String,
    connection: Connection,
    isEnabled: Bool)
    -> VCardSource
  {
    // if url has changed, ditch last import result
    let stamp = connection.url == self.connection.url ? lastImportResult : nil

    return VCardSource(
      name: name,
      connection: connection,
      isEnabled: isEnabled,
      id: id,
      lastImportResult: stamp)
  }

  func with(username username: String, password: String) -> VCardSource {
    let connection = Connection(
      url: self.connection.url,
      authenticationMethod: self.connection.authenticationMethod,
      username: username,
      password: password)
    return VCardSource(
      name: name,
      connection: connection,
      isEnabled: isEnabled,
      id: id,
      lastImportResult: lastImportResult)
  }

  func withLastImportResult(
    isSuccess: Bool,
    message: String,
    at importedAt: NSDate,
    modifiedHeaderStamp newModifiedHeaderStamp: ModifiedHeaderStamp?)
    -> VCardSource
  {
    // if no new modified header stamp, preserve the old one (if any)
    let stamp = newModifiedHeaderStamp ?? lastImportResult?.modifiedHeaderStamp

    return VCardSource(
      name: name,
      connection: connection,
      isEnabled: isEnabled,
      id: id,
      lastImportResult: VCardSource.ImportResult(
        isSuccess: isSuccess,
        message: message,
        importedAt: importedAt,
        modifiedHeaderStamp: stamp))
  }

  struct Connection {
    let url: String
    let authenticationMethod: HTTPRequest.AuthenticationMethod
    let username: String
    let password: String

    init(
      url: String,
      authenticationMethod: HTTPRequest.AuthenticationMethod,
      username: String = "",
      password: String = "")
    {
      self.url = url.trimmed  // needed by `toURL`
      self.authenticationMethod = authenticationMethod
      self.username = username
      self.password = password
    }

    static func empty() -> Connection {
      return self.init(url: "", authenticationMethod: .HTTPAuth)
    }

    func toURL() -> NSURL {
      return NSURL(string: url)!  // guaranteed by trimming in initializer
    }
  }

  struct ImportResult {
    let isSuccess: Bool
    let message: String
    let importedAt: NSDate
    let modifiedHeaderStamp: ModifiedHeaderStamp?
  }
}

extension VCardSource: DictionaryConvertible {
  func toDictionary() -> [String: AnyObject] {
    var dict: [String: AnyObject] = [
      "name": name,
      "connection": connection.toDictionary(),
      "isEnabled": isEnabled,
      "id": id
    ]
    if let importResult = lastImportResult {
      dict["lastImportResult"] = importResult.toDictionary()
    }
    return dict
  }

  static func fromDictionary(dictionary: [String: AnyObject]) -> VCardSource {
    var lastImportResult: ImportResult?
    if let importResult = dictionary["lastImportResult"] as? [String: AnyObject] {
       lastImportResult = VCardSource.ImportResult.fromDictionary(importResult)
    }

    return self.init(
      name: dictionary["name"] as! String,
      connection: Connection.fromDictionary(dictionary["connection"] as! [String: AnyObject]),
      isEnabled: dictionary["isEnabled"] as! Bool,
      id: dictionary["id"] as! String,
      lastImportResult: lastImportResult)
  }
}

extension VCardSource.Connection: DictionaryConvertible {
  func toDictionary() -> [String: AnyObject] {
    return [
      "url": url,
      "authenticationMethod": authenticationMethod.rawValue
    ]
  }

  static func fromDictionary(dictionary: [String: AnyObject]) -> VCardSource.Connection {
    return self.init(
      url: dictionary["url"] as! String,
      authenticationMethod: HTTPRequest.AuthenticationMethod(rawValue: dictionary["authenticationMethod"] as! String)!)
  }
}

extension VCardSource.ImportResult: DictionaryConvertible {
  func toDictionary() -> [String: AnyObject] {
    var dict: [String: AnyObject] = [
      "isSuccess": isSuccess,
      "message": message,
      "importedAt": importedAt.ISOString
    ]
    if let stamp = modifiedHeaderStamp {
      dict["modifiedHeaderStamp"] = stamp.toDictionary()
    }
    return dict
  }

  static func fromDictionary(dictionary: [String: AnyObject]) -> VCardSource.ImportResult {
    var modifiedHeaderStamp: ModifiedHeaderStamp?
    if let stamp = dictionary["modifiedHeaderStamp"] as? [String: AnyObject] {
      modifiedHeaderStamp = ModifiedHeaderStamp.fromDictionary(stamp)
    }

    return self.init(
      isSuccess: dictionary["isSuccess"] as! Bool,
      message: dictionary["message"] as! String,
      importedAt: NSDate.dateFromISOString(dictionary["importedAt"] as! String)!,
      modifiedHeaderStamp: modifiedHeaderStamp)
  }
}
