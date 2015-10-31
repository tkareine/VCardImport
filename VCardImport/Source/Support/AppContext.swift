import Foundation

class AppContext {
  let vcardSourceStore: VCardSourceStore
  let httpRequests: HTTPRequestable

  init(vcardSourceStore: VCardSourceStore, httpRequestsWith httpRequests: HTTPRequestable) {
    self.vcardSourceStore = vcardSourceStore
    self.httpRequests = httpRequests
  }
}
