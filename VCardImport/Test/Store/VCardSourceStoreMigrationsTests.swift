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

    let newSourceDict = VCardSource.fromDictionary(newSourceDicts.first!).toDictionary()

    XCTAssertEqual(newSourceDict["connection"]!["authenticationMethod"], "BasicAuth")
  }

  func testMigratesRenamedVCardURLKeyToVersion3() {
    let oldSourceDict: [String: AnyObject] = [
      "name": "Test",
      "connection": [
        "url": "https://example.com/vcards",
        "authenticationMethod": "BasicAuth"
      ],
      "isEnabled": true,
      "id": NSUUID().UUIDString
    ]

    let newSourceDicts = VCardSourceStoreMigrations.migrateNonSensitiveData(
      [oldSourceDict],
      previousVersion: 2)

    let newSourceDict = VCardSource.fromDictionary(newSourceDicts.first!).toDictionary()

    XCTAssertEqual(newSourceDict["connection"]!["vcardURL"], "https://example.com/vcards")
  }
}
