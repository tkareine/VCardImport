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
    let sourcesData = JSONSerialization.encode(store.map { key, value in (key, value.toDictionary()) })
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setInteger(1, forKey: "VCardSourcesVersion")
    defaults.setObject(sourcesData, forKey: "VCardSources")
    defaults.synchronize()
  }

  func load() {
    if let sourcesData = NSUserDefaults.standardUserDefaults().objectForKey("VCardSources") as? NSData {
      let obj = JSONSerialization.decode(sourcesData) as [String: [String: AnyObject]]
      store = obj.map { key, value in (key, VCardSource.fromDictionary(value)) }
    } else {
      let sources = [
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
      ]
      let ids = sources.map { $0.id }
      store = zipDictionary(ids, sources)
    }
  }
}
