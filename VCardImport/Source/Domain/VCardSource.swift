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
    let stamp = connection.vcardURL == self.connection.vcardURL ? lastImportResult : nil

    return VCardSource(
      name: name,
      connection: connection,
      isEnabled: isEnabled,
      id: id,
      lastImportResult: stamp)
  }

  func with(username username: String, password: String) -> VCardSource {
    let connection = Connection(
      vcardURL: self.connection.vcardURL,
      authenticationMethod: self.connection.authenticationMethod,
      username: username,
      password: password,
      loginURL: self.connection.loginURL)
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
    let vcardURL: String
    let authenticationMethod: HTTPRequest.AuthenticationMethod
    let username: String
    let password: String
    let loginURL: String?

    /**
     - precondition: if `authenticationMethod` parameter is `.PostForm`,
       `loginURL` parameter must be defined.
     */
    init(
      vcardURL: String,
      authenticationMethod: HTTPRequest.AuthenticationMethod,
      username: String = "",
      password: String = "",
      loginURL: String? = nil)
    {
      self.vcardURL = vcardURL.trimmed  // needed by `vcardURLasURL`
      self.authenticationMethod = authenticationMethod
      self.username = username
      self.password = password
      self.loginURL = authenticationMethod == .PostForm
        ? loginURL!.trimmed  // needed by `loginURLasURL`
        : nil
    }

    static func empty() -> Connection {
      return self.init(vcardURL: "", authenticationMethod: .HTTPAuth)
    }

    func vcardURLasURL() -> NSURL {
      return NSURL(string: vcardURL)!  // guaranteed by trimming in initializer
    }

    /// - precondition: `authenticationMethod` must be `.PostForm`
    func loginURLasURL() -> NSURL {
      return NSURL(string: loginURL!)!  // guaranteed by trimming in initializer
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
    var dict = [
      "vcardURL": vcardURL,
      "authenticationMethod": authenticationMethod.rawValue
    ]
    if let url = loginURL {
      dict["loginURL"] = url
    }
    return dict
  }

  static func fromDictionary(dictionary: [String: AnyObject]) -> VCardSource.Connection {
    let vcardURL = dictionary["vcardURL"] as! String
    let authenticationMethod = HTTPRequest.AuthenticationMethod(rawValue: dictionary["authenticationMethod"] as! String)!

    let loginURL: String?
    if let url = dictionary["loginURL"] as? String {
      loginURL = url
    } else {
      loginURL = nil
    }

    return self.init(
      vcardURL: vcardURL,
      authenticationMethod: authenticationMethod,
      loginURL: loginURL)
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
