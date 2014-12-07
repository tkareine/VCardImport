import Foundation

class VCardSourceStore {
  class var sharedStore: VCardSourceStore {
    struct Singleton {
      static let instance = VCardSourceStore()
    }
    return Singleton.instance
  }

  var sources: [VCardSource] {
    return _sources
  }

  private var _sources: [VCardSource]

  private init() {
    _sources = [VCardSource(name: "Reaktor", connection: VCardSource.Connection(url: "https://download.reaktor.fi/"))]
  }
}
