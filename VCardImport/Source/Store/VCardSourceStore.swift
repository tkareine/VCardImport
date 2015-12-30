import Foundation

private let CurrentStoreVersion = 3

class VCardSourceStore {
  private let keychainItem: KeychainItemWrapper
  private var store: InsertionOrderDictionary<String, VCardSource> = InsertionOrderDictionary()

  var isEmpty: Bool {
    return store.isEmpty
  }

  var countAll: Int {
    return store.count
  }

  var countEnabled: Int {
    return store.values.countWhere { $0.isEnabled }
  }

  var filterEnabled: [VCardSource] {
    return store.values.filter { $0.isEnabled }
  }

  init() {
    keychainItem = KeychainItemWrapper(
      account: Config.BundleIdentifier,
      service: Config.Persistence.CredentialsKey,
      accessGroup: nil)
  }

  subscript(index: Int) -> VCardSource {
    return store[index]
  }

  func hasSource(source: VCardSource) -> Bool {
    return store[source.id] != nil
  }

  func indexOf(source: VCardSource) -> Int? {
    return store.indexOf(source.id)
  }

  func update(source: VCardSource) {
    store[source.id] = source
  }

  func remove(index: Int) {
    store.removeValueAtIndex(index)
  }

  func move(fromIndex fromIndex: Int, toIndex: Int) {
    store.move(fromIndex: fromIndex, toIndex: toIndex)
  }

  func save() {
    saveNonSensitiveDataToUserDefaults(NSUserDefaults.standardUserDefaults())
    saveSensitiveDataToKeychain()
  }

  func load() {
    let userDefaults = NSUserDefaults.standardUserDefaults()
    let previousStoreVersion = userDefaults.integerForKey(Config.Persistence.VersionKey)
    let needsMigration = previousStoreVersion > 0 && previousStoreVersion < CurrentStoreVersion
    let sources = needsMigration
      ? migrateNonSensitiveDataFromUserDefaults(userDefaults, previousVersion: previousStoreVersion)
      : loadNonSensitiveDataFromUserDefaults(userDefaults)
    resetFrom(loadSensitiveDataFromKeychain(sources))
    if needsMigration {
      saveNonSensitiveDataToUserDefaults(userDefaults)
      NSLog("Migrated vCard sources from version %d to %d", previousStoreVersion, CurrentStoreVersion)
    }
  }

  // MARK: Helpers

  private func saveNonSensitiveDataToUserDefaults(userDefaults: NSUserDefaults) {
    // attempt to serialize vcard sources before persisting them
    let sourcesData = JSONSerialization.encode(store.values.map { $0.toDictionary() })
    userDefaults.setInteger(CurrentStoreVersion, forKey: Config.Persistence.VersionKey)
    userDefaults.setObject(sourcesData, forKey: Config.Persistence.VCardSourcesKey)
    userDefaults.synchronize()
  }

  private func saveSensitiveDataToKeychain() {
    func credentialsToDictionary() -> [String: [String: String]] {
      var result: [String: [String: String]] = [:]
      for (id, source) in store {
        let conn = source.connection
        var cred: [String: String] = [:]
        if !conn.username.isEmpty {
          cred["username"] = conn.username
        }
        if !conn.password.isEmpty {
          cred["password"] = conn.password
        }
        if !cred.isEmpty {
          result[id] = cred
        }
      }
      return result
    }

    let credsData = JSONSerialization.encode(credentialsToDictionary())
    keychainItem.setObject(credsData, forKey: kSecAttrGeneric)
  }

  private func migrateNonSensitiveDataFromUserDefaults(
    userDefaults: NSUserDefaults,
    previousVersion: Int)
    -> [VCardSource]
  {
    if let sourcesData = userDefaults.objectForKey(Config.Persistence.VCardSourcesKey) as? NSData {
      let oldSourcesDicts = JSONSerialization.decode(sourcesData) as! [[String: AnyObject]]
      let newSourcesDicts = VCardSourceStoreMigrations.migrateNonSensitiveData(
        oldSourcesDicts,
        previousVersion: previousVersion)
      return newSourcesDicts.map { VCardSource.fromDictionary($0) }
    } else {
      return []
    }
  }

  private func loadNonSensitiveDataFromUserDefaults(userDefaults: NSUserDefaults)
    -> [VCardSource]
  {
    if let sourcesData = userDefaults.objectForKey(Config.Persistence.VCardSourcesKey) as? NSData {
      return (JSONSerialization.decode(sourcesData) as! [[String: AnyObject]])
        .map { VCardSource.fromDictionary($0) }
    } else {
#if DEFAULT_SOURCES
      return makeDefaultSources()
#else
      return []
#endif
    }
  }

  private func loadSensitiveDataFromKeychain(sources: [VCardSource]) -> [VCardSource] {
    if let credsData = keychainItem.objectForKey(kSecAttrGeneric) as? NSData {
      let creds = JSONSerialization.decode(credsData) as! [String: [String: String]]
      return sources.map { source in
        if let cred = creds[source.id] {
          return source.with(username: cred["username"] ?? "", password: cred["password"] ?? "")
        } else {
          return source  // this source has no credentials
        }
      }
    } else {
      return sources  // no source has credentials
    }
  }

  private func resetFrom(sources: [VCardSource]) {
    var store: InsertionOrderDictionary<String, VCardSource> = InsertionOrderDictionary()
    for source in sources {
      store[source.id] = source
    }
    self.store = store
  }

#if DEFAULT_SOURCES
  private func makeDefaultSources() -> [VCardSource] {
    return [
      VCardSource(
        name: "Body Corp",
        connection: VCardSource.Connection(
          vcardURL: "https://dl.dropboxusercontent.com/u/1404049/vcards/bodycorp.vcf",
          authenticationMethod: .HTTPAuth),
        isEnabled: true),
      VCardSource(
        name: "Cold Temp",
        connection: VCardSource.Connection(
          vcardURL: "https://dl.dropboxusercontent.com/u/1404049/vcards/coldtemp.vcf",
          authenticationMethod: .HTTPAuth),
        isEnabled: true)
    ]
  }
#endif
}
