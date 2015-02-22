import Foundation

struct Files {
  static func tempURL() -> NSURL {
    let fileName = NSProcessInfo.processInfo().globallyUniqueString
    return NSURL.fileURLWithPath(NSTemporaryDirectory().stringByAppendingPathComponent(fileName))!
  }

  static func copy(#from: NSURL, to: NSURL) {
    var error: NSError?

    NSFileManager.defaultManager().copyItemAtURL(from, toURL: to, error: &error)

    if let err = error {
      fatalError("Failed to copy file from \(from) to \(to): \(err)")
    }
  }

  static func move(#from: NSURL, to: NSURL) {
    var error: NSError?

    NSFileManager.defaultManager().moveItemAtURL(from, toURL: to, error: &error)

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

    fileManager.removeItemAtURL(fileURL, error: &error)

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
