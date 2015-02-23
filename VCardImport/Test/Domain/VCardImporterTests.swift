import AddressBook
import XCTest

class VCardImporterTests: XCTestCase {
  let TestOrganization = "VCardImport Tests"

  let firstSource = VCardSource(
    name: "First Source",
    connection: VCardSource.Connection(
      url: "https://example.com/vcards/first.vcf"),
    isEnabled: true)

  let secondSource = VCardSource(
    name: "Second Source",
    connection: VCardSource.Connection(
      url: "https://example.com/vcards/second.vcf"),
    isEnabled: true)

  override func setUp() {
    super.setUp()
    removeTestRecordsFromAddressBook()
  }

  func testAddsRecordToAddressBook() {
    let importSourceCompletionExpectation = expectationWithDescription("import source completion")
    let importCompletionExpectation = expectationWithDescription("import completion")

    let importer = makeVCardImporter(
      onSourceDownload: { _, _ in () },
      onSourceComplete: { source, changeResult, _, error in
        XCTAssertNil(error)
        XCTAssertEqual(source.id, self.firstSource.id)
        XCTAssertEqual(changeResult!.additions, 1)
        XCTAssertEqual(changeResult!.updates, 0)
        importSourceCompletionExpectation.fulfill()
      },
      onComplete: { error in
        XCTAssertNil(error)
        importCompletionExpectation.fulfill()
      })

    importer.importFrom([firstSource])

    waitForExpectationsWithTimeout(1, handler: nil)

    let record: ABRecord! = loadTestRecordFromAddressBook()
    XCTAssertNotNil(record)

    let jobTitle = Records.getSingleValueProperty(kABPersonJobTitleProperty, of: record) as String!
    XCTAssertEqual(jobTitle, "Test Subject")

    let emails = Records.getMultiValueProperty(kABPersonEmailProperty, of: record) as [(NSString, NSObject)]!
    XCTAssertEqual(emails.count, 1)
    XCTAssertEqual(emails.first!.1, "amelie.alpha@example.com")

    let phones = Records.getMultiValueProperty(kABPersonPhoneProperty, of: record) as [(NSString, NSObject)]!
    XCTAssertEqual(phones.count, 1)
    XCTAssertEqual(phones.first!.0, kABPersonPhoneMobileLabel)
    XCTAssertEqual(phones.first!.1, "5551001001")
  }

  func testUpdatesRecordInAddressBook() {
    addTestRecordToAddressBook(
      jobTitle: "Existing Test Subject",
      phones: [(kABPersonPhoneIPhoneLabel, "5551001002")])

    let importSourceCompletionExpectation = expectationWithDescription("import source completion")
    let importCompletionExpectation = expectationWithDescription("import completion")

    let importer = makeVCardImporter(
      onSourceDownload: { _, _ in () },
      onSourceComplete: { src, changeResult, _, error in
        XCTAssertNil(error)
        XCTAssertEqual(src.id, self.firstSource.id)
        XCTAssertEqual(changeResult!.additions, 0)
        XCTAssertEqual(changeResult!.updates, 1)
        importSourceCompletionExpectation.fulfill()
      },
      onComplete: { error in
        XCTAssertNil(error)
        importCompletionExpectation.fulfill()
      })

    importer.importFrom([firstSource])

    waitForExpectationsWithTimeout(1, handler: nil)

    let record: ABRecord! = loadTestRecordFromAddressBook()
    XCTAssertNotNil(record)

    let jobTitle = Records.getSingleValueProperty(kABPersonJobTitleProperty, of: record) as String!
    XCTAssertEqual(jobTitle, "Existing Test Subject")

    let emails = Records.getMultiValueProperty(kABPersonEmailProperty, of: record) as [(NSString, NSObject)]!
    XCTAssertEqual(emails.count, 1)
    XCTAssertEqual(emails.first!.1, "amelie.alpha@example.com")

    let phones = Records.getMultiValueProperty(kABPersonPhoneProperty, of: record) as [(NSString, NSObject)]!
    XCTAssertEqual(phones.count, 2)
    XCTAssertEqual(phones[0].0, kABPersonPhoneIPhoneLabel)
    XCTAssertEqual(phones[0].1, "5551001002")
    XCTAssertEqual(phones[1].0, kABPersonPhoneMobileLabel)
    XCTAssertEqual(phones[1].1, "5551001001")
  }

  func testSameRecordGetsAddedOnlyOnce() {
    let importCompletionExpectation = expectationWithDescription("import completion")
    var sourceCompletions: [String: ChangedRecordsResult] = [:]

    let importer = makeVCardImporter(
      onSourceDownload: { _, _ in () },
      onSourceComplete: { source, changeResult, _, error in
        sourceCompletions[source.id] = changeResult
      },
      onComplete: { error in
        XCTAssertNil(error)
        importCompletionExpectation.fulfill()
    })

    importer.importFrom([firstSource, secondSource])

    waitForExpectationsWithTimeout(1, handler: nil)

    let firstSourceChangeResult = sourceCompletions[firstSource.id]!
    XCTAssertEqual(firstSourceChangeResult.additions, 1)
    XCTAssertEqual(firstSourceChangeResult.updates, 0)

    let secondSourceChangeResult = sourceCompletions[secondSource.id]!
    XCTAssertEqual(secondSourceChangeResult.additions, 0)
    XCTAssertEqual(secondSourceChangeResult.updates, 0)

    let record: ABRecord! = loadTestRecordFromAddressBook()
    XCTAssertNotNil(record)

    let emails = Records.getMultiValueProperty(kABPersonEmailProperty, of: record) as [(NSString, NSObject)]!
    XCTAssertEqual(emails.count, 1)

    let phones = Records.getMultiValueProperty(kABPersonPhoneProperty, of: record) as [(NSString, NSObject)]!
    XCTAssertEqual(phones.count, 1)
  }

  func testSameRecordUpdateGetsAppliedOnlyOnce() {
    addTestRecordToAddressBook(
      jobTitle: "Existing Test Subject",
      phones: [(kABPersonPhoneIPhoneLabel, "5551001002")])

    let importCompletionExpectation = expectationWithDescription("import completion")
    var sourceCompletions: [String: ChangedRecordsResult] = [:]

    let importer = makeVCardImporter(
      onSourceDownload: { _, _ in () },
      onSourceComplete: { source, changeResult, _, error in
        sourceCompletions[source.id] = changeResult
      },
      onComplete: { error in
        XCTAssertNil(error)
        importCompletionExpectation.fulfill()
    })

    importer.importFrom([firstSource, secondSource])

    waitForExpectationsWithTimeout(1, handler: nil)

    let firstSourceChangeResult = sourceCompletions[firstSource.id]!
    XCTAssertEqual(firstSourceChangeResult.additions, 0)
    XCTAssertEqual(firstSourceChangeResult.updates, 1)

    let secondSourceChangeResult = sourceCompletions[secondSource.id]!
    XCTAssertEqual(secondSourceChangeResult.additions, 0)
    XCTAssertEqual(secondSourceChangeResult.updates, 0)

    let record: ABRecord! = loadTestRecordFromAddressBook()
    XCTAssertNotNil(record)

    let emails = Records.getMultiValueProperty(kABPersonEmailProperty, of: record) as [(NSString, NSObject)]!
    XCTAssertEqual(emails.count, 1)

    let phones = Records.getMultiValueProperty(kABPersonPhoneProperty, of: record) as [(NSString, NSObject)]!
    XCTAssertEqual(phones.count, 2)
  }

  /**
    Thread synchronization note: We need to reinstantiate the address book
    object after running `VCardImporter#import` to ensure we see the latest
    state of the address book. This is because VCardImporter accesses the
    address book from a different thread.
  */
  private func makeAddressBook() -> AddressBook {
    var error: NSError?
    let addressBook = AddressBook(error: &error)
    if let err = error {
      fatalError("Failed to make address book: \(err)")
    }
    return addressBook!
  }

  private func recordIsOfTestOrganization(record: ABRecord) -> Bool {
    let orgName = Records.getSingleValueProperty(kABPersonOrganizationProperty, of: record)
    return orgName == TestOrganization
  }

  private func loadTestRecordFromAddressBook() -> ABRecord? {
    let records = makeAddressBook()
      .loadRecordsWithName("Amelie Alpha")
      .filter(recordIsOfTestOrganization)
    if records.count > 1 {
      fatalError("Expected zero or one test record, found \(records.count)")
    }
    return records.isEmpty ? nil : records.first
  }

  private func removeTestRecordsFromAddressBook() {
    let addressBook = makeAddressBook()
    let records = addressBook.loadRecords().filter(recordIsOfTestOrganization)
    var error: NSError?
    addressBook.removeRecords(records, error: &error)
    if let err = error {
      fatalError("Failed to remove test record: \(err)")
    }
    addressBook.save(error: &error)
    if let err = error {
      fatalError("Failed to save address book: \(err)")
    }
  }

  private func addTestRecordToAddressBook(
    #jobTitle: NSString,
    phones: [(NSString, NSString)])
  {
    let record: ABRecord = TestRecords.makePerson(
      firstName: "Amelie",
      lastName: "Alpha",
      jobTitle: jobTitle,
      organization: TestOrganization,
      phones: phones)
    let addressBook = makeAddressBook()
    var error: NSError?
    addressBook.addRecords([record], error: &error)
    if let err = error {
      fatalError("Failed to add test record: \(err)")
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
