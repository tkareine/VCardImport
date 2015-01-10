import Foundation

class VCardSourceStore {
  private var sourceIds: [String] = []
  private var sourcesByIds: [String: VCardSource] = [:]

  var isEmpty: Bool {
    return sourceIds.isEmpty
  }

  var countAll: Int {
    return sourceIds.count
  }

  var countEnabled: Int {
    return countWhere(sourcesByIds.values, { $0.isEnabled })
  }

  var filterEnabled: [VCardSource] {
    return filter(sourcesByIds.values, { $0.isEnabled })
  }

  init() {}

  subscript(index: Int) -> VCardSource {
    get {
      let sourceId = sourceIds[index]
      return sourcesByIds[sourceId]!
    }
  }

  func indexOf(source: VCardSource) -> Int {
    return find(sourceIds, source.id)!
  }

  func update(source: VCardSource) {
    sourcesByIds[source.id] = source
  }

  func remove(index: Int) {
    let sourceId = sourceIds[index]
    sourceIds.removeAtIndex(index)
    sourcesByIds.removeValueForKey(sourceId)
  }

  func save() {
    let sourcesData = JSONSerialization.encode(snapshotStore().map { $0.toDictionary() })
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setInteger(1, forKey: "VCardSourcesVersion")
    defaults.setObject(sourcesData, forKey: "VCardSources")
    defaults.synchronize()
  }

  func load() {
    if let sourcesData = NSUserDefaults.standardUserDefaults().objectForKey("VCardSources") as? NSData {
      let sources = (JSONSerialization.decode(sourcesData) as [[String: AnyObject]])
        .map { VCardSource.fromDictionary($0) }
      resetStore(sources)
    } else {
      resetStore([
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

  private func snapshotStore() -> [VCardSource] {
    var sources: [VCardSource] = []
    for id in sourceIds {
      sources.append(sourcesByIds[id]!)
    }
    return sources
  }

  private func resetStore(sources: [VCardSource]) {
    var sourceIds: [String] = []
    var sourcesByIds: [String: VCardSource] = [:]

    for source in sources {
      sourceIds.append(source.id)
      sourcesByIds[source.id] = source
    }

    self.sourceIds = sourceIds
    self.sourcesByIds = sourcesByIds
  }
}
