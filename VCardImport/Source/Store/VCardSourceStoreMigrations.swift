import Foundation

struct VCardSourceStoreMigrations {
  static func migrateNonSensitiveData(
    sources: [[String: AnyObject]],
    previousVersion: Int)
    -> [[String: AnyObject]]
  {
    var srcs = sources

    if previousVersion < 2 {
      srcs = srcs.map(vcardSourceWithAuthenticationMethod)
    }

    if previousVersion < 3 {
      srcs = srcs.map(vcardSourceWithRenamedVCardURLKey)
    }

    if previousVersion < 4 {
      srcs = srcs.map(vcardSourceWithIncludePersonNicknameForEqualityOption)
    }

    return srcs
  }

  private static func vcardSourceWithAuthenticationMethod(
    sourceDict: [String: AnyObject])
    -> [String: AnyObject]
  {
    var srcDct = sourceDict
    var connection = srcDct["connection"] as! [String: AnyObject]
    connection["authenticationMethod"] = HTTPRequest.AuthenticationMethod.BasicAuth.rawValue
    srcDct["connection"] = connection
    return srcDct
  }

  private static func vcardSourceWithRenamedVCardURLKey(
    sourceDict: [String: AnyObject])
    -> [String: AnyObject]
  {
    var srcDct = sourceDict
    var connection = srcDct["connection"] as! [String: AnyObject]
    connection["vcardURL"] = connection.removeValueForKey("url")
    srcDct["connection"] = connection
    return srcDct
  }

  private static func vcardSourceWithIncludePersonNicknameForEqualityOption(
    sourceDict: [String: AnyObject])
    -> [String: AnyObject]
  {
    var srcDct = sourceDict
    srcDct["includePersonNicknameForEquality"] = false
    return srcDct
  }
}
