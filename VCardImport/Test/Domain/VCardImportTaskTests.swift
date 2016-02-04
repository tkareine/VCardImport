import AddressBook
import MiniFuture
import XCTest

class VCardImportTaskTests: XCTestCase {
  let TestOrganization = "VCardImport Tests"
  let OneTestRecordVCardFile = "amelie-alpha"
  let DuplicateTestRecordsVCardFile = "amelie-alpha-3x"

  let addressBook = try! AddressBook.sharedInstance()

  override func setUp() {
    super.setUp()
    removeTestRecordsFromAddressBook()
  }

  func testAddsRecordToAddressBook() {
    let importSourceCompletionExpectation = expectationWithDescription("import source completion")
    let importCompletionExpectation = expectationWithDescription("import completion")
    let source = makeVCardSource()

    let importer = makeVCardImportTask(
      usingHTTPSession: makeHTTPSession(
        downloadURL: source.connection.vcardURLasURL(),
        fromFile: OneTestRecordVCardFile),
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

    let record = loadTestRecordFromAddressBook()!
    XCTAssertNotNil(record)

    let jobTitle = Records.getSingleValueProperty(kABPersonJobTitleProperty, of: record) as! String
    XCTAssertEqual(jobTitle, "Test Subject")

    let emails = Records.getMultiValueProperty(kABPersonEmailProperty, of: record)
    XCTAssertEqual(emails.count, 1)
    XCTAssertEqual((emails.first!.1 as! String), "amelie.alpha@example.com")

    let phones = Records.getMultiValueProperty(kABPersonPhoneProperty, of: record)
    XCTAssertEqual(phones.count, 1)
    XCTAssertEqual(phones.first!.0, kABPersonPhoneMobileLabel as String)
    XCTAssertEqual((phones.first!.1 as! String), "5551001001")
  }

  func testUpdatesRecordInAddressBook() {
    addTestRecordToAddressBook(
      jobTitle: "Existing Test Subject",
      phones: [(kABPersonPhoneIPhoneLabel as String, "5551001002")])

    let importSourceCompletionExpectation = expectationWithDescription("import source completion")
    let importCompletionExpectation = expectationWithDescription("import completion")
    let source = makeVCardSource()

    let importer = makeVCardImportTask(
      usingHTTPSession: makeHTTPSession(
        downloadURL: source.connection.vcardURLasURL(),
        fromFile: OneTestRecordVCardFile),
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

    let record = loadTestRecordFromAddressBook()!
    XCTAssertNotNil(record)

    let jobTitle = Records.getSingleValueProperty(kABPersonJobTitleProperty, of: record) as! String
    XCTAssertEqual(jobTitle, "Existing Test Subject")

    let emails = Records.getMultiValueProperty(kABPersonEmailProperty, of: record)
    XCTAssertEqual(emails.count, 1)
    XCTAssertEqual((emails.first!.1 as! String), "amelie.alpha@example.com")

    let phones = Records.getMultiValueProperty(kABPersonPhoneProperty, of: record)
    XCTAssertEqual(phones.count, 2)
    XCTAssertEqual(phones[0].0, kABPersonPhoneIPhoneLabel as String)
    XCTAssertEqual((phones[0].1 as! String), "5551001002")
    XCTAssertEqual(phones[1].0, kABPersonPhoneMobileLabel as String)
    XCTAssertEqual((phones[1].1 as! String), "5551001001")
  }

  func testSameRecordGetsAddedOnlyOnce() {
    let importCompletionExpectation = expectationWithDescription("import completion")
    let firstSource = makeVCardSource("first")
    let secondSource = makeVCardSource("second")
    let httpSession = FakeHTTPSession()

    httpSession.fakeDownload(firstSource.connection.vcardURLasURL(), file: OneTestRecordVCardFile)
    httpSession.fakeDownload(secondSource.connection.vcardURLasURL(), file: OneTestRecordVCardFile)

    var sourceCompletions: [String: RecordDifferences] = [:]

    let importer = makeVCardImportTask(
      usingHTTPSession: httpSession,
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

    let record = loadTestRecordFromAddressBook()!
    XCTAssertNotNil(record)

    let emails = Records.getMultiValueProperty(kABPersonEmailProperty, of: record)
    XCTAssertEqual(emails.count, 1)

    let phones = Records.getMultiValueProperty(kABPersonPhoneProperty, of: record)
    XCTAssertEqual(phones.count, 1)
  }

  func testSameRecordUpdateGetsAppliedOnlyOnce() {
    addTestRecordToAddressBook(
      jobTitle: "Existing Test Subject",
      phones: [(kABPersonPhoneIPhoneLabel as String, "5551001002")])

    let importCompletionExpectation = expectationWithDescription("import completion")
    let firstSource = makeVCardSource("first")
    let secondSource = makeVCardSource("second")
    let httpSession = FakeHTTPSession()

    httpSession.fakeDownload(firstSource.connection.vcardURLasURL(), file: OneTestRecordVCardFile)
    httpSession.fakeDownload(secondSource.connection.vcardURLasURL(), file: OneTestRecordVCardFile)

    var sourceCompletions: [String: RecordDifferences] = [:]

    let importer = makeVCardImportTask(
      usingHTTPSession: httpSession,
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

    let record = loadTestRecordFromAddressBook()!
    XCTAssertNotNil(record)

    let emails = Records.getMultiValueProperty(kABPersonEmailProperty, of: record)
    XCTAssertEqual(emails.count, 1)

    let phones = Records.getMultiValueProperty(kABPersonPhoneProperty, of: record)
    XCTAssertEqual(phones.count, 2)
  }

  func testSkipsNewRecordsFromVCardFileDueToDuplicateNames() {
    let importSourceCompletionExpectation = expectationWithDescription("import source completion")
    let importCompletionExpectation = expectationWithDescription("import completion")
    let source = makeVCardSource()

    let importer = makeVCardImportTask(
      usingHTTPSession: makeHTTPSession(
        downloadURL: source.connection.vcardURLasURL(),
        fromFile: DuplicateTestRecordsVCardFile),
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

    let importer = makeVCardImportTask(
      usingHTTPSession: makeHTTPSession(
        downloadURL: source.connection.vcardURLasURL(),
        fromFile: OneTestRecordVCardFile),
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

  func testReturnsNilModifiedHeaderStampIfRemoteDoesNotSupportHTTPCaching() {
    let importSourceCompletionExpectation = expectationWithDescription("import source completion")
    let importCompletionExpectation = expectationWithDescription("import completion")
    let source = makeVCardSource()

    let importer = makeVCardImportTask(
      usingHTTPSession: makeHTTPSession(
        downloadURL: source.connection.vcardURLasURL(),
        fromFile: OneTestRecordVCardFile),
      onSourceComplete: { _, _, modifiedHeaderStamp, error in
        XCTAssertNil(modifiedHeaderStamp)
        XCTAssertNil(error)
        importSourceCompletionExpectation.fulfill()
      },
      onComplete: { error in
        XCTAssertNil(error)
        importCompletionExpectation.fulfill()
    })

    importer.importFrom([source])

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testReturnsModifiedHeaderStampIfRemoteSupportsHTTPCachingWithLastModifiedHeader() {
    let importSourceCompletionExpectation = expectationWithDescription("import source completion")
    let importCompletionExpectation = expectationWithDescription("import completion")
    let source = makeVCardSource()
    let vcardURL = source.connection.vcardURLasURL()

    let httpSession = makeHTTPSession(
      downloadURL: vcardURL,
      fromFile: OneTestRecordVCardFile)

    httpSession.fakeRespondTo(
      vcardURL,
      withResponse: makeHTTPResponse(
        url: vcardURL,
        headerFields: ["Last-Modified": "Fri, 1 Jan 2016 00:43:54 GMT"]))

    let importer = makeVCardImportTask(
      usingHTTPSession: httpSession,
      onSourceComplete: { _, recordDiff, modifiedHeaderStamp, error in
        XCTAssertNotNil(recordDiff)
        XCTAssertEqual(modifiedHeaderStamp, ModifiedHeaderStamp(name: "Last-Modified", value: "Fri, 1 Jan 2016 00:43:54 GMT"))
        XCTAssertNil(error)
        importSourceCompletionExpectation.fulfill()
      },
      onComplete: { error in
        XCTAssertNil(error)
        importCompletionExpectation.fulfill()
    })

    importer.importFrom([source])

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testReturnsModifiedHeaderStampIfRemoteSupportsHTTPCachingWithETagHeader() {
    let importSourceCompletionExpectation = expectationWithDescription("import source completion")
    let importCompletionExpectation = expectationWithDescription("import completion")
    let source = makeVCardSource()
    let vcardURL = source.connection.vcardURLasURL()

    let httpSession = makeHTTPSession(
      downloadURL: vcardURL,
      fromFile: OneTestRecordVCardFile)

    httpSession.fakeRespondTo(
      vcardURL,
      withResponse: makeHTTPResponse(
        url: vcardURL,
        headerFields: ["ETag": "1407855624n"]))

    let importer = makeVCardImportTask(
      usingHTTPSession: httpSession,
      onSourceComplete: { _, recordDiff, modifiedHeaderStamp, error in
        XCTAssertNotNil(recordDiff)
        XCTAssertEqual(modifiedHeaderStamp, ModifiedHeaderStamp(name: "ETag", value: "1407855624n"))
        XCTAssertNil(error)
        importSourceCompletionExpectation.fulfill()
      },
      onComplete: { error in
        XCTAssertNil(error)
        importCompletionExpectation.fulfill()
    })

    importer.importFrom([source])

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testDoesNotDownloadVCardFileIfHTTPCachingHeaderStampSignifiesNoChangeInRemoteFile() {
    let importSourceCompletionExpectation = expectationWithDescription("import source completion")
    let importCompletionExpectation = expectationWithDescription("import completion")
    let modifiedHeaderStamp = ModifiedHeaderStamp(name: "ETag", value: "1407855624n")
    let source = makeVCardSource().withLastImportResult(
      true,
      message: "Downloaded",
      at: NSDate(),
      modifiedHeaderStamp: modifiedHeaderStamp)
    let vcardURL = source.connection.vcardURLasURL()

    let httpSession = makeHTTPSession(
      downloadURL: vcardURL,
      fromFile: OneTestRecordVCardFile)

    httpSession.fakeRespondTo(
      vcardURL,
      withResponse: makeHTTPResponse(
        url: vcardURL,
        headerFields: ["ETag": "1407855624n"]))

    let importer = makeVCardImportTask(
      usingHTTPSession: httpSession,
      onSourceComplete: { _, recordDiff, modifiedHeaderStamp, error in
        XCTAssertNil(recordDiff)
        XCTAssertNil(modifiedHeaderStamp)
        XCTAssertNil(error)
        importSourceCompletionExpectation.fulfill()
      },
      onComplete: { error in
        XCTAssertNil(error)
        importCompletionExpectation.fulfill()
    })

    importer.importFrom([source])

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testDownloadsVCardFileIfRemoteDoesNotSupportHTTPCachingAndPreviousHeaderStampExists() {
    let importSourceCompletionExpectation = expectationWithDescription("import source completion")
    let importCompletionExpectation = expectationWithDescription("import completion")
    let modifiedHeaderStamp = ModifiedHeaderStamp(name: "ETag", value: "1407855624n")
    let source = makeVCardSource().withLastImportResult(
      true,
      message: "Downloaded",
      at: NSDate(),
      modifiedHeaderStamp: modifiedHeaderStamp)
    let vcardURL = source.connection.vcardURLasURL()

    let httpSession = makeHTTPSession(
      downloadURL: vcardURL,
      fromFile: OneTestRecordVCardFile)

    httpSession.fakeRespondTo(
      vcardURL,
      withResponse: makeHTTPResponse(url: vcardURL))

    let importer = makeVCardImportTask(
      usingHTTPSession: httpSession,
      onSourceComplete: { _, recordDiff, modifiedHeaderStamp, error in
        XCTAssertNotNil(recordDiff)
        XCTAssertNil(modifiedHeaderStamp)
        XCTAssertNil(error)
        importSourceCompletionExpectation.fulfill()
      },
      onComplete: { error in
        XCTAssertNil(error)
        importCompletionExpectation.fulfill()
    })

    importer.importFrom([source])

    waitForExpectationsWithTimeout(1, handler: nil)
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
    try! addressBook.removeRecords(records)
    try! addressBook.save()
  }

  private func addTestRecordToAddressBook(
    jobTitle jobTitle: String,
    phones: [(String, NSString)]? = nil)
  {
    let record = TestRecords.makePerson(
      firstName: "Amelie",
      lastName: "Alpha",
      jobTitle: jobTitle,
      organization: TestOrganization,
      phones: phones)
    try! addressBook.addRecord(record)
    try! addressBook.save()
  }

  func makeVCardSource(name: String = "amelie-alpha") -> VCardSource {
    return VCardSource(
      name: name,
      connection: VCardSource.Connection(
        vcardURL: "https://example.com/vcards/\(name).vcf",
        authenticationMethod: .None),
      includePersonNicknameForEquality: true,
      isEnabled: true)
  }

  private func makeHTTPResponse(
    url url: NSURL,
    headerFields: [String: String] = [:])
    -> NSHTTPURLResponse
  {
    return NSHTTPURLResponse(
      URL: url,
      statusCode: 200,
      HTTPVersion: "HTTP/1.1",
      headerFields: headerFields)!
  }

  private func makeHTTPSession(
    downloadURL url: NSURL,
    fromFile file: String)
    -> FakeHTTPSession
  {
    let session = FakeHTTPSession()
    session.fakeDownload(url, file: file)
    return session
  }

  private func makeVCardImportTask(
    usingHTTPSession httpSession: HTTPRequestable,
    onSourceComplete: VCardImportTask.OnSourceCompleteCallback,
    onComplete: VCardImportTask.OnCompleteCallback)
    -> VCardImportTask
  {
    return VCardImportTask(
      downloadsWith: URLDownloadFactory(httpSessionsWith: { httpSession }),
      queueTo: QueueExecution.mainQueue,
      sourceCompletionHandler: onSourceComplete,
      completionHandler: onComplete)
  }
}
