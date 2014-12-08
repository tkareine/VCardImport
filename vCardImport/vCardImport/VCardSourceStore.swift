import Foundation

class VCardSourceStore {
  class var sharedStore: VCardSourceStore {
    struct Singleton {
      static let instance = VCardSourceStore()
    }
    return Singleton.instance
  }

  private var sources: [VCardSource]

  var count: Int {
    return sources.count
  }

  private init() {
    sources = [VCardSource(name: "Reaktor", connection: VCardSource.Connection(url: "https://download.reaktor.fi/"))]
  }

  subscript(index: Int) -> VCardSource {
    get {
      return sources[index]
    }

    set {
      sources[index] = newValue
    }
  }
}
