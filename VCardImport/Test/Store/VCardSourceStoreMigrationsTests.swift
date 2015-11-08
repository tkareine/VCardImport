import XCTest

class VCardSourceStoreMigrationTests: XCTestCase {
  func testMigratesAuthenticationMethodForVersion1() {
    var oldSourceDict = VCardSource.empty().toDictionary()
    var oldConnectionDict = oldSourceDict["connection"] as! [String: AnyObject]
    oldConnectionDict.removeValueForKey("authenticationMethod")
    oldSourceDict["connection"] = oldConnectionDict

    XCTAssertNil(oldSourceDict["connection"]!["authenticationMethod"])

    let newSourceDicts = VCardSourceStoreMigrations.migrateNonSensitiveData(
      [oldSourceDict],
      previousVersion: 1)

    let newSource = VCardSource.fromDictionary(newSourceDicts.first!)

    XCTAssertEqual(newSource.connection.authenticationMethod, HTTPRequest.AuthenticationMethod.HTTPAuth)
  }
}
