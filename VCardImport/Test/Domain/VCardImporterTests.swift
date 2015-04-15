import AddressBook
import MiniFuture
import XCTest

class VCardImporterTests: XCTestCase {
  let TestOrganization = "VCardImport Tests"
  let OneTestRecordVCardFile = "amelie-alpha"
  let DuplicateTestRecordsVCardFile = "amelie-alpha-3x"

  let addressBook = VCardImporterTests.makeAddressBook()

  override func setUp() {
    super.setUp()
    removeTestRecordsFromAddressBook()
  }

  func testAddsRecordToAddressBook() {
    let importSourceCompletionExpectation = expectationWithDescription("import source completion")
    let importCompletionExpectation = expectationWithDescription("import completion")
    let source = makeVCardSource()

    let importer = makeVCardImporter(
      usingVCardFile: OneTestRecordVCardFile,
      onSourceComplete: { src, recordDiff, _, error in
        XCTAssertNil(error)
        XCTAssertEqual(src.id, source.id)
        XCTAssertEqual(recordDiff!.additions.count, 1)
        XCTAssertEqual(recordDiff!.changes.count, 0)
        importSourceCompletionExpectation.fulfill()
      },
      onComplete: { error in
        XCTAssertNil(error)
        importCompletionExpectation.fulfill()
      })

    importer.importFrom([source])

    waitForExpectationsWithTimeout(1, handler: nil)

    let record: ABRecord! = loadTestRecordFromAddressBook()
    XCTAssertNotNil(record)

    let jobTitle = Records.getSingleValueProperty(kABPersonJobTitleProperty, of: record) as! String
    XCTAssertEqual(jobTitle, "Test Subject")

    let emails = Records.getMultiValueProperty(kABPersonEmailProperty, of: record)!
    XCTAssertEqual(emails.count, 1)
    XCTAssertEqual(emails.first!.1 as! String, "amelie.alpha@example.com")

    let phones = Records.getMultiValueProperty(kABPersonPhoneProperty, of: record)!
    XCTAssertEqual(phones.count, 1)
    XCTAssertEqual(phones.first!.0, kABPersonPhoneMobileLabel as String)
    XCTAssertEqual(phones.first!.1 as! String, "5551001001")
  }

  func testUpdatesRecordInAddressBook() {
    addTestRecordToAddressBook(
      jobTitle: "Existing Test Subject",
      phones: [(kABPersonPhoneIPhoneLabel as String, "5551001002")])

    let importSourceCompletionExpectation = expectationWithDescription("import source completion")
    let importCompletionExpectation = expectationWithDescription("import completion")
    let source = makeVCardSource()

    let importer = makeVCardImporter(
      usingVCardFile: OneTestRecordVCardFile,
      onSourceComplete: { src, recordDiff, _, error in
        XCTAssertNil(error)
        XCTAssertEqual(src.id, source.id)
        XCTAssertEqual(recordDiff!.additions.count, 0)
        XCTAssertEqual(recordDiff!.changes.count, 1)
        importSourceCompletionExpectation.fulfill()
      },
      onComplete: { error in
        XCTAssertNil(error)
        importCompletionExpectation.fulfill()
      })

    importer.importFrom([source])

    waitForExpectationsWithTimeout(1, handler: nil)

    let record: ABRecord! = loadTestRecordFromAddressBook()
    XCTAssertNotNil(record)

    let jobTitle = Records.getSingleValueProperty(kABPersonJobTitleProperty, of: record) as! String
    XCTAssertEqual(jobTitle, "Existing Test Subject")

    let emails = Records.getMultiValueProperty(kABPersonEmailProperty, of: record)!
    XCTAssertEqual(emails.count, 1)
    XCTAssertEqual(emails.first!.1 as! String, "amelie.alpha@example.com")

    let phones = Records.getMultiValueProperty(kABPersonPhoneProperty, of: record)!
    XCTAssertEqual(phones.count, 2)
    XCTAssertEqual(phones[0].0, kABPersonPhoneIPhoneLabel as String)
    XCTAssertEqual(phones[0].1 as! String, "5551001002")
    XCTAssertEqual(phones[1].0, kABPersonPhoneMobileLabel as String)
    XCTAssertEqual(phones[1].1 as! String, "5551001001")
  }

  func testSameRecordGetsAddedOnlyOnce() {
    let importCompletionExpectation = expectationWithDescription("import completion")
    let firstSource = makeVCardSource("first")
    let secondSource = makeVCardSource("second")
    var sourceCompletions: [String: RecordDifferences] = [:]

    let importer = makeVCardImporter(
      usingVCardFile: OneTestRecordVCardFile,
      onSourceComplete: { source, recordDiff, _, error in
        XCTAssertNil(error)
        sourceCompletions[source.id] = recordDiff!
      },
      onComplete: { error in
        XCTAssertNil(error)
        importCompletionExpectation.fulfill()
    })

    importer.importFrom([firstSource, secondSource])

    waitForExpectationsWithTimeout(1, handler: nil)

    let firstSourceChangeResult = sourceCompletions[firstSource.id]!
    XCTAssertEqual(firstSourceChangeResult.additions.count, 1)
    XCTAssertEqual(firstSourceChangeResult.changes.count, 0)

    let secondSourceChangeResult = sourceCompletions[secondSource.id]!
    XCTAssertEqual(secondSourceChangeResult.additions.count, 0)
    XCTAssertEqual(secondSourceChangeResult.changes.count, 0)

    let record: ABRecord! = loadTestRecordFromAddressBook()
    XCTAssertNotNil(record)

    let emails = Records.getMultiValueProperty(kABPersonEmailProperty, of: record)!
    XCTAssertEqual(emails.count, 1)

    let phones = Records.getMultiValueProperty(kABPersonPhoneProperty, of: record)!
    XCTAssertEqual(phones.count, 1)
  }

  func testSameRecordUpdateGetsAppliedOnlyOnce() {
    addTestRecordToAddressBook(
      jobTitle: "Existing Test Subject",
      phones: [(kABPersonPhoneIPhoneLabel as String, "5551001002")])

    let importCompletionExpectation = expectationWithDescription("import completion")
    let firstSource = makeVCardSource("first")
    let secondSource = makeVCardSource("second")
    var sourceCompletions: [String: RecordDifferences] = [:]

    let importer = makeVCardImporter(
      usingVCardFile: OneTestRecordVCardFile,
      onSourceComplete: { source, recordDiff, _, error in
        XCTAssertNil(error)
        sourceCompletions[source.id] = recordDiff!
      },
      onComplete: { error in
        XCTAssertNil(error)
        importCompletionExpectation.fulfill()
    })

    importer.importFrom([firstSource, secondSource])

    waitForExpectationsWithTimeout(1, handler: nil)

    let firstSourceChangeResult = sourceCompletions[firstSource.id]!
    XCTAssertEqual(firstSourceChangeResult.additions.count, 0)
    XCTAssertEqual(firstSourceChangeResult.changes.count, 1)

    let secondSourceChangeResult = sourceCompletions[secondSource.id]!
    XCTAssertEqual(secondSourceChangeResult.additions.count, 0)
    XCTAssertEqual(secondSourceChangeResult.changes.count, 0)

    let record: ABRecord! = loadTestRecordFromAddressBook()
    XCTAssertNotNil(record)

    let emails = Records.getMultiValueProperty(kABPersonEmailProperty, of: record)!
    XCTAssertEqual(emails.count, 1)

    let phones = Records.getMultiValueProperty(kABPersonPhoneProperty, of: record)!
    XCTAssertEqual(phones.count, 2)
  }

  func testSkipsNewRecordsFromVCardFileDueToDuplicateNames() {
    let importSourceCompletionExpectation = expectationWithDescription("import source completion")
    let importCompletionExpectation = expectationWithDescription("import completion")
    let source = makeVCardSource()

    let importer = makeVCardImporter(
      usingVCardFile: DuplicateTestRecordsVCardFile,
      onSourceComplete: { src, recordDiff, _, error in
        XCTAssertNil(error)
        XCTAssertEqual(src.id, source.id)
        XCTAssertEqual(recordDiff!.additions.count, 0)
        XCTAssertEqual(recordDiff!.changes.count, 0)
        XCTAssertEqual(recordDiff!.countSkippedNewRecordsWithDuplicateNames, 3)
        XCTAssertEqual(recordDiff!.countSkippedAmbiguousMatchesToExistingRecords, 0)
        importSourceCompletionExpectation.fulfill()
      },
      onComplete: { error in
        XCTAssertNil(error)
        importCompletionExpectation.fulfill()
    })

    importer.importFrom([source])

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testSkipsUpdateToExistingRecordDueToAmbiguousNameMatch() {
    addTestRecordToAddressBook(jobTitle: "Existing Test Subject")
    addTestRecordToAddressBook(jobTitle: "Duplicated Test Subject")
    addTestRecordToAddressBook(jobTitle: "Another Duplicated Test Subject")

    let importSourceCompletionExpectation = expectationWithDescription("import source completion")
    let importCompletionExpectation = expectationWithDescription("import completion")
    let source = makeVCardSource()

    let importer = makeVCardImporter(
      usingVCardFile: OneTestRecordVCardFile,
      onSourceComplete: { src, recordDiff, _, error in
        XCTAssertNil(error)
        XCTAssertEqual(src.id, source.id)
        XCTAssertEqual(recordDiff!.additions.count, 0)
        XCTAssertEqual(recordDiff!.changes.count, 0)
        XCTAssertEqual(recordDiff!.countSkippedNewRecordsWithDuplicateNames, 0)
        XCTAssertEqual(recordDiff!.countSkippedAmbiguousMatchesToExistingRecords, 3)
        importSourceCompletionExpectation.fulfill()
      },
      onComplete: { error in
        XCTAssertNil(error)
        importCompletionExpectation.fulfill()
    })

    importer.importFrom([source])

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  private class func makeAddressBook() -> AddressBook {
    var error: NSError?
    let addressBook = AddressBook.sharedInstance(error: &error)
    if let err = error {
      fatalError("Failed to make address book: \(err)")
    }
    return addressBook!
  }

  private func recordIsOfTestOrganization(record: ABRecord) -> Bool {
    if let orgName = Records.getSingleValueProperty(kABPersonOrganizationProperty, of: record) as? String {
      return orgName == TestOrganization
    } else {
      return false
    }
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

  private func removeTestRecordsFromAddressBook() {
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
    #jobTitle: String,
    phones: [(String, NSString)]? = nil)
  {
    let record: ABRecord = TestRecords.makePerson(
      firstName: "Amelie",
      lastName: "Alpha",
      jobTitle: jobTitle,
      organization: TestOrganization,
      phones: phones)
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

  func makeVCardSource(_ name: String = "amelie-alpha") -> VCardSource {
    return VCardSource(
      name: name,
      connection: VCardSource.Connection(
        url: "https://example.com/vcards/\(name).vcf"),
      isEnabled: true)
  }

  private func makeVCardImporter(
    usingVCardFile vcardFile: String,
    onSourceComplete: VCardImporter.OnSourceCompleteCallback,
    onComplete: VCardImporter.OnCompleteCallback)
    -> VCardImporter
  {
    return VCardImporter.builder()
      .connectWith(FakeURLConnection(using: vcardFile))
      .queueTo(QueueExecution.mainQueue)
      .onSourceDownload({ _, _ in () })
      .onSourceComplete(onSourceComplete)
      .onComplete(onComplete)
      .build()
  }

  private class FakeURLConnection: URLConnectable {
    let vcardFile: String

    init(using vcardFile: String) {
      self.vcardFile = vcardFile
    }

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
      let src = NSBundle(forClass: VCardImporterTests.self)
        .URLForResource(vcardFile, withExtension: "vcf")!
      Files.copy(from: src, to: dst)
      return Future.succeeded(dst)
    }
  }
}
