import XCTest

class VCardImportProgressTests: XCTestCase {
  func testSteppingTwoSources() {
    let importProgress = VCardImportProgress(sourceIds: ["a", "b"])

    var progress = importProgress.step(.Downloading(completionStepRatio: 0.4), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.14), 0.005)

    progress = importProgress.step(.Downloading(completionStepRatio: 0.4), forId: "b")
    XCTAssertEqualWithAccuracy(progress, Float(0.28), 0.005)

    progress = importProgress.step(.Downloading(completionStepRatio: 0.2), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.35), 0.005)

    progress = importProgress.step(.Downloading(completionStepRatio: 0.5), forId: "b")
    XCTAssertEqualWithAccuracy(progress, Float(0.52), 0.005)

    progress = importProgress.step(.Completed, forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.81), 0.005)

    progress = importProgress.step(.Completed, forId: "b")
    XCTAssertEqualWithAccuracy(progress, Float(1.0), 0.005)
  }

  func testSourcesCompletingWithoutDownloadProgress() {
    let importProgress = VCardImportProgress(sourceIds: ["a", "b"])

    var progress = importProgress.step(.Completed, forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.5), 0.005)

    progress = importProgress.step(.Completed, forId: "b")
    XCTAssertEqualWithAccuracy(progress, Float(1.0), 0.005)
  }

  func testSourcesCompletingManyTimes() {
    let importProgress = VCardImportProgress(sourceIds: ["a", "b"])

    var progress = importProgress.step(.Completed, forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.5), 0.005)

    progress = importProgress.step(.Completed, forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.5), 0.005)

    progress = importProgress.step(.Completed, forId: "b")
    XCTAssertEqualWithAccuracy(progress, Float(1.0), 0.005)

    progress = importProgress.step(.Completed, forId: "b")
    XCTAssertEqualWithAccuracy(progress, Float(1.0), 0.005)
  }

  func testSourceExceedingDownloadProgressBudget() {
    let importProgress = VCardImportProgress(sourceIds: ["a"])

    var progress = importProgress.step(.Downloading(completionStepRatio: 0.7), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.49), 0.005)

    progress = importProgress.step(.Downloading(completionStepRatio: 0.6), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.70), 0.005)

    progress = importProgress.step(.Downloading(completionStepRatio: 0.5), forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(0.70), 0.005)

    progress = importProgress.step(.Completed, forId: "a")
    XCTAssertEqualWithAccuracy(progress, Float(1.0), 0.005)
  }
}
