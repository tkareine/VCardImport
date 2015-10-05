import XCTest

class FilesTests: XCTestCase {
  func testWithTempFile() {
    let tempPath: NSURL = Files.withTempURL { path in
      self.touch(path)
      return path
    }

    XCTAssertFalse(exists(tempPath))
  }

  func testCopy() {
    Files.withTempURL { source -> Void in
      self.touch(source)
      XCTAssertTrue(self.exists(source))

      Files.withTempURL { destination -> Void in
        Files.copy(from: source, to: destination)
        XCTAssertTrue(self.exists(source))
        XCTAssertTrue(self.exists(destination))
      }
    }
  }

  func testMove() {
    Files.withTempURL { source -> Void in
      self.touch(source)
      XCTAssertTrue(self.exists(source))

      Files.withTempURL { destination -> Void in
        Files.move(from: source, to: destination)
        XCTAssertFalse(self.exists(source))
        XCTAssertTrue(self.exists(destination))
      }
    }
  }

  private func exists(path: NSURL) -> Bool {
    return NSFileManager.defaultManager().fileExistsAtPath(path.path!)
  }

  private func touch(path: NSURL) {
    var error: NSError?
    do {
      try "".writeToURL(path, atomically: true, encoding: NSUTF8StringEncoding)
    } catch let error1 as NSError {
      error = error1
    }
    if let err = error {
      fatalError("Failed in touching file \(path): \(err)")
    }
  }
}
