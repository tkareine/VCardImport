import XCTest

class FilesTests: XCTestCase {
  func testWithTempFile() {
    let tempPath: NSURL = Files.withTempFile { path in
      self.touchFile(path)
      return path
    }

    XCTAssertFalse(fileExists(tempPath))
  }

  func testMove() {
    Files.withTempFile { source -> Void in
      self.touchFile(source)
      XCTAssertTrue(self.fileExists(source))

      Files.withTempFile { destination -> Void in
        Files.moveFile(source, to: destination)
        XCTAssertFalse(self.fileExists(source))
        XCTAssertTrue(self.fileExists(destination))
      }
    }
  }

  private func fileExists(path: NSURL) -> Bool {
    return NSFileManager.defaultManager().fileExistsAtPath(path.path!)
  }

  private func touchFile(path: NSURL) {
    var error: NSError?
    "".writeToURL(path, atomically: true, encoding: NSUTF8StringEncoding, error: &error)
    if let err = error {
      fatalError("Failed in touching file \(path): \(err)")
    }
  }
}
