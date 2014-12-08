import Foundation

class VCardSourceStore {
  private var sources: [VCardSource] = []

  var count: Int {
    return sources.count
  }

  init() {}

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
