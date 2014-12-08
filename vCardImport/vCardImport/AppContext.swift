import Foundation

class AppContext {
  let vcardImporter: VCardImporter
  let vcardSourceStore: VCardSourceStore

  init(vcardImporter: VCardImporter, vcardSourceStore: VCardSourceStore) {
    self.vcardImporter = vcardImporter
    self.vcardSourceStore = vcardSourceStore
  }
}
