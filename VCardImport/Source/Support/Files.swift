import Foundation

struct Files {
  static func tempURL() -> NSURL {
    let fileName = NSProcessInfo.processInfo().globallyUniqueString
    return NSURL.fileURLWithPath(NSTemporaryDirectory()).URLByAppendingPathComponent(fileName)
  }

  static func copy(from from: NSURL, to: NSURL) {
    var error: NSError?

    do {
      try NSFileManager.defaultManager().copyItemAtURL(from, toURL: to)
    } catch let error1 as NSError {
      error = error1
    }

    if let err = error {
      fatalError("Failed to copy file from \(from) to \(to): \(err)")
    }
  }

  static func move(from from: NSURL, to: NSURL) {
    var error: NSError?

    do {
      try NSFileManager.defaultManager().moveItemAtURL(from, toURL: to)
    } catch let error1 as NSError {
      error = error1
    }

    if let err = error {
      fatalError("Failed to move file from \(from) to \(to): \(err)")
    }
  }

  static func remove(fileURL: NSURL) {
    let fileManager = NSFileManager.defaultManager()

    if !fileManager.fileExistsAtPath(fileURL.path!) {
      return
    }

    var error: NSError?

    do {
      try fileManager.removeItemAtURL(fileURL)
    } catch let error1 as NSError {
      error = error1
    }

    if let err = error {
      fatalError("Failed to remove file at \(fileURL): \(err)")
    }
  }

  static func withTempURL<T>(block: (NSURL) -> T) -> T {
    let fileURL = tempURL()
    let result = block(fileURL)
    remove(fileURL)
    return result
  }
}
