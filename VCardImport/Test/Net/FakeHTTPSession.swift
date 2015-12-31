import Foundation
import MiniFuture

class FakeHTTPSession: HTTPRequestable {
  private var fakeDownloadFiles: [NSURL: String] = [:]
  private var fakeResponses: [NSURL: NSHTTPURLResponse] = [:]

  func fakeDownload(url: NSURL, file: String) {
    fakeDownloadFiles[url] = file
  }

  func fakeRespondTo(url: NSURL, withResponse response: NSHTTPURLResponse) {
    fakeResponses[url] = response
  }

  func defaultFakeResponseTo(url: NSURL) -> NSHTTPURLResponse {
    return NSHTTPURLResponse(
      URL: url,
      statusCode: 200,
      HTTPVersion: "HTTP/1.1",
      headerFields: [:])!
  }

  func head(
    url: NSURL,
    headers: HTTPRequest.Headers,
    credential: NSURLCredential?)
    -> Future<NSHTTPURLResponse>
  {
    return request(.HEAD, url: url, headers: headers, credential: credential)
  }

  func post(
    url: NSURL,
    headers: HTTPRequest.Headers,
    parameters: HTTPRequest.Parameters)
    -> Future<NSHTTPURLResponse>
  {
    return request(.POST, url: url, headers: headers)
  }

  func download(
    url: NSURL,
    to destination: NSURL,
    headers: HTTPRequest.Headers,
    credential: NSURLCredential?,
    onProgress: HTTPRequest.OnProgressCallback?)
    -> Future<NSURL>
  {
    guard let file = fakeDownloadFiles[url] else {
      fatalError("no fake download file for \(url)")
    }
    let dst = Files.tempURL()
    let src = NSBundle(forClass: VCardImporterTests.self)
      .URLForResource(file, withExtension: "vcf")!
    Files.copy(from: src, to: dst)
    return Future.succeeded(dst)
  }

  private func request(
    method: HTTPRequest.RequestMethod,
    url: NSURL,
    headers: HTTPRequest.Headers,
    credential: NSURLCredential? = nil,
    onProgress: HTTPRequest.OnProgressCallback? = nil)
    -> Future<NSHTTPURLResponse>
  {
    let response: NSHTTPURLResponse

    if let cannedResponse = fakeResponses[url] {
      response = cannedResponse
    } else {
      response = defaultFakeResponseTo(url)
    }

    return Future.succeeded(response)
  }
}
