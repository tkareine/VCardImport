import Foundation

struct Files {
  static func tempFile() -> NSURL {
    let fileName = NSProcessInfo.processInfo().globallyUniqueString
    return NSURL.fileURLWithPath(NSTemporaryDirectory().stringByAppendingPathComponent(fileName))!
  }

  static func moveFile(from: NSURL, to: NSURL) {
    var error: NSError?

    NSFileManager.defaultManager().moveItemAtURL(from, toURL: to, error: &error)

    if let err = error {
      fatalError("Failed moving file: \(err)")
    }
  }

  static func removeFile(fileURL: NSURL) {
    let fileManager = NSFileManager.defaultManager()

    if !fileManager.fileExistsAtPath(fileURL.path!) {
      return
    }

    var error: NSError?

    fileManager.removeItemAtURL(fileURL, error: &error)

    if let err = error {
      fatalError("Failed removing file: \(err)")
    }
  }

  static func withTempFile<T>(block: (NSURL) -> T) -> T {
    let fileURL = tempFile()
    let result = block(fileURL)
    removeFile(fileURL)
    return result
  }
}
