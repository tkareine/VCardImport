import Foundation

class VCardSourceStore {
  class var sharedStore: VCardSourceStore {
    struct Singleton {
      static let instance = VCardSourceStore()
    }
    return Singleton.instance
  }

  private var sources: [VCardSource] = []

  var count: Int {
    return sources.count
  }

  private init() {
    load()
  }

  subscript(index: Int) -> VCardSource {
    get {
      return sources[index]
    }

    set {
      sources[index] = newValue
    }
  }

  func save() {
    let sourcesData = NSKeyedArchiver.archivedDataWithRootObject(sources)
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setObject(sourcesData, forKey: "VCardSources")
    defaults.synchronize()
  }

  func load() {
    if let sourcesData = NSUserDefaults.standardUserDefaults().objectForKey("VCardSources") as? NSData {
      sources = NSKeyedUnarchiver.unarchiveObjectWithData(sourcesData) as Array<VCardSource>
    } else {
      sources = [VCardSource(name: "Reaktor", connection: VCardSource.Connection(url: "https://download.reaktor.fi/"))]
    }
  }
}
