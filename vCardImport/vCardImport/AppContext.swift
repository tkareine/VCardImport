import Foundation

class AppContext {
  let vcardSourceStore: VCardSourceStore

  init(vcardSourceStore: VCardSourceStore) {
    self.vcardSourceStore = vcardSourceStore
  }
}
