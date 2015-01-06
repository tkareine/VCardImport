import XCTest

class FilesTests: XCTestCase {
  func testWithTempFile() {
    let tempPath: NSURL = Files.withTempFile { path in
      let wasWritten = "foo".writeToURL(path, atomically: true, encoding: NSUTF8StringEncoding, error: nil)

      XCTAssertTrue(wasWritten)

      return path
    }

    XCTAssertFalse(NSFileManager.defaultManager().fileExistsAtPath(tempPath.path!))
  }
}
