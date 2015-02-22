import Foundation

class AppContext {
  let vcardSourceStore: VCardSourceStore
  let urlConnection: URLConnectable

  init(vcardSourceStore: VCardSourceStore, urlConnection: URLConnectable) {
    self.vcardSourceStore = vcardSourceStore
    self.urlConnection = urlConnection
  }
}
