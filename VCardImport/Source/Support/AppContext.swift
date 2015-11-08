import Foundation

class AppContext {
  let vcardSourceStore: VCardSourceStore
  let urlDownloadFactory: URLDownloadFactory

  init(
    vcardSourceStore: VCardSourceStore,
    urlDownloadsWith urlDownloadFactory: URLDownloadFactory)
  {
    self.vcardSourceStore = vcardSourceStore
    self.urlDownloadFactory = urlDownloadFactory
  }
}
