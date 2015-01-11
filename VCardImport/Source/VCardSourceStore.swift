import Foundation

class VCardSourceStore {
  private var store: InsertionOrderDictionary<String, VCardSource> = InsertionOrderDictionary()

  var isEmpty: Bool {
    return store.isEmpty
  }

  var countAll: Int {
    return store.count
  }

  var countEnabled: Int {
    return countWhere(store.values, { $0.isEnabled })
  }

  var filterEnabled: [VCardSource] {
    return filter(store.values, { $0.isEnabled })
  }

  init() {}

  subscript(index: Int) -> VCardSource {
    return store[index]
  }

  func indexOf(source: VCardSource) -> Int {
    return store.indexOf(source.id)!
  }

  func update(source: VCardSource) {
    store[source.id] = source
  }

  func remove(index: Int) {
    store.removeValueAtIndex(index)
  }

  func move(#fromIndex: Int, toIndex: Int) {
    store.move(fromIndex: fromIndex, toIndex: toIndex)
  }

  func save() {
    let sourcesData = JSONSerialization.encode(store.values.map { $0.toDictionary() })
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setInteger(1, forKey: "VCardSourcesVersion")
    defaults.setObject(sourcesData, forKey: "VCardSources")
    defaults.synchronize()
  }

  func load() {
    if let sourcesData = NSUserDefaults.standardUserDefaults().objectForKey("VCardSources") as? NSData {
      let sources = (JSONSerialization.decode(sourcesData) as [[String: AnyObject]])
        .map { VCardSource.fromDictionary($0) }
      resetFrom(sources)
    } else {
      resetFrom([
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

  private func resetFrom(sources: [VCardSource]) {
    var store: InsertionOrderDictionary<String, VCardSource> = InsertionOrderDictionary()
    for source in sources {
      store[source.id] = source
    }
    self.store = store
  }
}
