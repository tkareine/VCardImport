import AddressBook
import XCTest

class VCardImporterTests: XCTestCase {
  var addressBook: AddressBook!

  override func setUp() {
    super.setUp()
    addressBook = makeAddressBook()
    removeTestRecordsFromAddressBook()
  }

  func testImportsContacts() {
    let importCompletionExpectation = expectationWithDescription("import completion")
    let importer = makeVCardImporter(
      onSourceDownload: { _, _ in () },
      onSourceComplete: { source, changes, stamp, error in
        XCTAssertNil(error)
        XCTAssertEqual(changes!.additions, 1)
        XCTAssertEqual(changes!.changes, 0)
      },
      onComplete: { error in
        XCTAssertNil(error)
        importCompletionExpectation.fulfill()
      })
    importer.importFrom([VCardSource.empty()])

    waitForExpectationsWithTimeout(1, handler: nil)

    let record: ABRecord? = loadTestRecordFromAddressBook()
    XCTAssertNotNil(record)
  }

  private func makeAddressBook() -> AddressBook {
    var error: NSError?
    let addressBook = AddressBook(error: &error)
    if let err = error {
      fatalError("Failed to make address book: \(err)")
    }
    return addressBook!
  }

  private func loadTestRecordFromAddressBook() -> ABRecord? {
    let records = addressBook
      .loadRecordsWithName("Amelie Alpha")
      .filter(recordIsOfTestOrganization)
    if records.count > 1 {
      fatalError("Expected zero or one test record, found \(records.count)")
    }
    return records.isEmpty ? nil : records.first
  }

  private func loadTestRecordsFromAddressBook() -> [ABRecord] {
    return addressBook.loadRecords().filter(recordIsOfTestOrganization)
  }

  private func recordIsOfTestOrganization(record: ABRecord) -> Bool {
    let orgName = Records.getSingleValueProperty(kABPersonOrganizationProperty, of: record)
    return orgName == "VCardImport Tests"
  }

  private func removeTestRecordsFromAddressBook() {
    var error: NSError?
    addressBook.removeRecords(loadTestRecordsFromAddressBook(), error: &error)
    if let err = error {
      fatalError("Failed to remove test record: \(err)")
    }
    addressBook.save(error: &error)
    if let err = error {
      fatalError("Failed to save address book: \(err)")
    }
  }

  private func makeVCardImporter(
    #onSourceDownload: VCardImporter.OnSourceDownloadCallback,
    onSourceComplete: VCardImporter.OnSourceCompleteCallback,
    onComplete: VCardImporter.OnCompleteCallback)
    -> VCardImporter
  {
    return VCardImporter.builder()
      .connectWith(FakeURLConnection())
      .queueTo(QueueExecution.mainQueue)
      .onSourceDownload(onSourceDownload)
      .onSourceComplete(onSourceComplete)
      .onComplete(onComplete)
      .build()
  }

  private class FakeURLConnection: URLConnectable {
    func request(
      method: Request.Method,
      url: NSURL,
      headers: Request.Headers,
      credential: NSURLCredential?,
      onProgress: Request.OnProgressCallback? = nil)
      -> Future<NSHTTPURLResponse>
    {
      return Future.succeeded(NSHTTPURLResponse(
        URL: url,
        statusCode: 200,
        HTTPVersion: "HTTP/1.1",
        headerFields: [:])!)
    }

    func head(
      url: NSURL,
      headers: Request.Headers,
      credential: NSURLCredential?)
      -> Future<NSHTTPURLResponse>
    {
      return request(.HEAD, url: url, headers: headers, credential: credential)
    }

    func download(
      url: NSURL,
      to destination: NSURL,
      headers: Request.Headers,
      credential: NSURLCredential?,
      onProgress: Request.OnProgressCallback?)
      -> Future<NSURL>
    {
      let dst = Files.tempURL()
      let src = NSBundle(forClass: VCardImporterTests.self).URLForResource("amelie-alpha", withExtension: "vcf")!
      Files.copy(from: src, to: dst)
      return Future.succeeded(dst)
    }
  }
}
