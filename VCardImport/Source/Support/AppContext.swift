import Foundation

class AppContext {
  let vcardSourceStore: VCardSourceStore
  let urlConnection: URLConnection

  init(vcardSourceStore: VCardSourceStore, urlConnection: URLConnection) {
    self.vcardSourceStore = vcardSourceStore
    self.urlConnection = urlConnection
  }
}
