import XCTest

class VCardSourceStoreMigrationTests: XCTestCase {
  func testMigratesAuthenticationMethodForVersion2() {
    let oldSourceDict: [String: AnyObject] = [
      "name": "Test",
      "connection": [
        "url": "https://example.com/vcards"
      ],
      "isEnabled": true,
      "id": NSUUID().UUIDString
    ]

    let newSourceDicts = VCardSourceStoreMigrations.migrateNonSensitiveData(
      [oldSourceDict],
      previousVersion: 1)

    let newSource = VCardSource.fromDictionary(newSourceDicts.first!)

    XCTAssertEqual(newSource.connection.authenticationMethod, HTTPRequest.AuthenticationMethod.HTTPAuth)
  }

  func testMigratesRenamedVCardURLKeyToVersion3() {
    let oldSourceDict: [String: AnyObject] = [
      "name": "Test",
      "connection": [
        "url": "https://example.com/vcards",
        "authenticationMethod": "HTTPAuth"
      ],
      "isEnabled": true,
      "id": NSUUID().UUIDString
    ]

    let newSourceDicts = VCardSourceStoreMigrations.migrateNonSensitiveData(
      [oldSourceDict],
      previousVersion: 2)

    let newSource = VCardSource.fromDictionary(newSourceDicts.first!)

    XCTAssertEqual(newSource.connection.vcardURL, "https://example.com/vcards")
  }
}
