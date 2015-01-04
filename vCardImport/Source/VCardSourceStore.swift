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
    func serializeJSON(obj: AnyObject) -> NSData {
      var err: NSError?
      if let data = NSJSONSerialization.dataWithJSONObject(obj, options: nil, error: &err) {
        return data
      } else {
        fatalError("JSON serialization failed: \(err!)")
      }
    }

    let sourcesData = serializeJSON(sources.map { $0.toDictionary() })
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setInteger(1, forKey: "VCardSourcesVersion")
    defaults.setObject(sourcesData, forKey: "VCardSources")
    defaults.synchronize()
  }

  func load() {
    func deserializeJSON(data: NSData) -> AnyObject {
      var err: NSError?
      if let obj: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &err) {
        return obj
      } else {
        fatalError("JSON deserialization failed: \(err!)")
      }
    }

    if let sourcesData = NSUserDefaults.standardUserDefaults().objectForKey("VCardSources") as? NSData {
      let obj = deserializeJSON(sourcesData) as [[String: AnyObject]]
      sources = obj.map { VCardSource.fromDictionary($0) }
    } else {
      sources = [
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
    }
  }
}
