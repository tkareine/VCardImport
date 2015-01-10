import Foundation

class VCardSourceStore {
  private var store: [String: VCardSource] = [:]

  var sourceIds: [String] {
    return Array(store.keys)
  }

  var countAll: Int {
    return store.count
  }

  var countEnabled: Int {
    return countWhere(store, { $0.1.isEnabled })
  }

  var filterEnabled: [VCardSource] {
    return filter(store.values, { $0.isEnabled })
  }

  init() {}

  subscript(key: String) -> VCardSource {
    get {
      return store[key]!
    }

    set {
      store[key] = newValue
    }
  }

  func remove(id: String) {
    store.removeValueForKey(id)
  }

  func save() {
    let sourcesData = JSONSerialization.encode(Array(store.values).map { $0.toDictionary() })
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setInteger(1, forKey: "VCardSourcesVersion")
    defaults.setObject(sourcesData, forKey: "VCardSources")
    defaults.synchronize()
  }

  func load() {
    if let sourcesData = NSUserDefaults.standardUserDefaults().objectForKey("VCardSources") as? NSData {
      let sources = (JSONSerialization.decode(sourcesData) as [[String: AnyObject]])
        .map { VCardSource.fromDictionary($0) }
      store = toDictionary(sources)
    } else {
      store = toDictionary([
        VCardSource(
          name: "Example: Body Corp",
          connection: VCardSource.Connection(url: NSURL(string: "https://dl.dropboxusercontent.com/u/1404049/vcards/bodycorp.vcf")!),
          isEnabled: true
        ),
        VCardSource(
          name: "Example: Cold Temp",
          connection: VCardSource.Connection(url: NSURL(string: "https://dl.dropboxusercontent.com/u/1404049/vcards/coldtemp.vcf")!),
          isEnabled: true
        )
      ])
    }
  }

  private func toDictionary(sources: [VCardSource]) -> [String: VCardSource] {
    return mapDictionary(sources) { _, source in source.id }
  }
}
