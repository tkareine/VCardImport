import Foundation

struct VCardSourceStoreMigrations {
  static func migrateNonSensitiveData(
    var sources: [[String: AnyObject]],
    previousVersion: Int)
    -> [[String: AnyObject]]
  {
    if previousVersion < 2 {
      sources = sources.map(vcardSourceWithAuthenticationMethod)
    }

    if previousVersion < 3 {
      sources = sources.map(vcardSourceWithRenamedVCardURLKey)
    }

    if previousVersion < 4 {
      sources = sources.map(vcardSourceWithIncludePersonNicknameForEqualityOption)
    }

    return sources
  }

  private static func vcardSourceWithAuthenticationMethod(
    var sourceDict: [String: AnyObject])
    -> [String: AnyObject]
  {
    var connection = sourceDict["connection"] as! [String: AnyObject]
    connection["authenticationMethod"] = HTTPRequest.AuthenticationMethod.BasicAuth.rawValue
    sourceDict["connection"] = connection
    return sourceDict
  }

  private static func vcardSourceWithRenamedVCardURLKey(
    var sourceDict: [String: AnyObject])
    -> [String: AnyObject]
  {
    var connection = sourceDict["connection"] as! [String: AnyObject]
    connection["vcardURL"] = connection.removeValueForKey("url")
    sourceDict["connection"] = connection
    return sourceDict
  }

  private static func vcardSourceWithIncludePersonNicknameForEqualityOption(
    var sourceDict: [String: AnyObject])
    -> [String: AnyObject]
  {
    sourceDict["includePersonNicknameForEquality"] = false
    return sourceDict
  }
}
