import XCTest

private let FloatEqualsAccuracy: Float = 0.001

class ImportProgressTests: XCTestCase {
  func testProgressingOneSource() {
    let importProgress = ImportProgress(sourceIds: ["a"])

    var progress = importProgress.inProgress(.Download(completionRatio: 0.1), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.070), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.Download(completionRatio: 0.2), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.140), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.Download(completionRatio: 0.9), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.630), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.ResolveRecords(completionRatio: 0.5), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.750), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.ApplyRecords(completionRatio: 0.5), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.850), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.Complete, forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(1.000), accuracy: FloatEqualsAccuracy)
  }

  func testProgressingTwoSources() {
    let importProgress = ImportProgress(sourceIds: ["a", "b"])

    var progress = importProgress.inProgress(.Download(completionRatio: 0.4), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.140), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.Download(completionRatio: 0.5), forId: "b")
    XCTAssertEqualWithAccuracy(progress, Float(0.315), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.Download(completionRatio: 0.7), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.420), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.Download(completionRatio: 0.6), forId: "b")
    XCTAssertEqualWithAccuracy(progress, Float(0.455), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.ResolveRecords(completionRatio: 0.5), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.585), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.ResolveRecords(completionRatio: 0.5), forId: "b")
    XCTAssertEqualWithAccuracy(progress, Float(0.750), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.ApplyRecords(completionRatio: 0.5), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.800), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.ApplyRecords(completionRatio: 0.5), forId: "b")
    XCTAssertEqualWithAccuracy(progress, Float(0.850), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.Complete, forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.925), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.Complete, forId: "b")
    XCTAssertEqualWithAccuracy(progress, Float(1.000), accuracy: FloatEqualsAccuracy)
  }

  func testProgressDirectlyToCompletion() {
    let importProgress = ImportProgress(sourceIds: ["a"])

    let progress = importProgress.inProgress(.Complete, forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(1.000), accuracy: FloatEqualsAccuracy)
  }

  func testProgressingWithoutAllIntermediateEvents() {
    let importProgress = ImportProgress(sourceIds: ["a"])

    var progress = importProgress.inProgress(.ResolveRecords(completionRatio: 0.0), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.700), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.Complete, forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(1.000), accuracy: FloatEqualsAccuracy)
  }

  func testProgressingWithSmallerRatioThanLastRatio() {
    let importProgress = ImportProgress(sourceIds: ["a"])

    var progress = importProgress.inProgress(.Download(completionRatio: 0.6), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.420), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.Download(completionRatio: 0.2), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.420), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.ResolveRecords(completionRatio: 0.8), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.780), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.ResolveRecords(completionRatio: 0.2), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.780), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.ApplyRecords(completionRatio: 0.6), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.860), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.ApplyRecords(completionRatio: 0.2), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.860), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.Complete, forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(1.000), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.Complete, forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(1.000), accuracy: FloatEqualsAccuracy)
  }

  func testProgressingWithOldEvents() {
    let importProgress = ImportProgress(sourceIds: ["a"])

    var progress = importProgress.inProgress(.Download(completionRatio: 0.6), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.420), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.ApplyRecords(completionRatio: 0.6), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.860), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.ResolveRecords(completionRatio: 0.2), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.860), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.ApplyRecords(completionRatio: 0.2), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.860), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.Complete, forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(1.000), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.Complete, forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(1.000), accuracy: FloatEqualsAccuracy)
  }

  func testProgressingWithTooBigRatio() {
    let importProgress = ImportProgress(sourceIds: ["a"])

    var progress = importProgress.inProgress(.Download(completionRatio: 1.2), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.700), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.ResolveRecords(completionRatio: 1.2), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.800), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.ApplyRecords(completionRatio: 1.2), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.900), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.Complete, forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(1.000), accuracy: FloatEqualsAccuracy)
  }

  func testProgressingWithTooSmallRatio() {
    let importProgress = ImportProgress(sourceIds: ["a"])

    var progress = importProgress.inProgress(.Download(completionRatio: -0.2), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.000), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.Download(completionRatio: 0.0), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.000), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.ResolveRecords(completionRatio: -0.2), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.700), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.ResolveRecords(completionRatio: 0.0), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.700), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.ApplyRecords(completionRatio: -0.2), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.800), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.ApplyRecords(completionRatio: 0.0), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.800), accuracy: FloatEqualsAccuracy)

    progress = importProgress.inProgress(.Complete, forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(1.000), accuracy: FloatEqualsAccuracy)
  }
}
