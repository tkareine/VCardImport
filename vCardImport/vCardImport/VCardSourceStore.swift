import Foundation

class VCardSourceStore {
  private var sources: [VCardSource] = []

  var countAll: Int {
    return sources.count
  }

  var countEnabled: Int {
    return sources.countWhere { $0.isEnabled }
  }

  var first: VCardSource? {
    return sources.first
  }

  var filterEnabled: [VCardSource] {
    return sources.filter { $0.isEnabled }
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
    defaults.setInteger(1, forKey: "VCardSourcesVersion")
    defaults.setObject(sourcesData, forKey: "VCardSources")
    defaults.synchronize()
  }

  func load() {
    if let sourcesData = NSUserDefaults.standardUserDefaults().objectForKey("VCardSources") as? NSData {
      sources = NSKeyedUnarchiver.unarchiveObjectWithData(sourcesData) as Array<VCardSource>
    } else {
      sources = [
        VCardSource(
          name: "Reaktor",
          connection: VCardSource.Connection(url: NSURL(string: "https://download.reaktor.fi/")!),
          isEnabled: true
        )
      ]
    }
  }
}
