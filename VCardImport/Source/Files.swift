import Foundation

struct Files {
  static func tempFile() -> NSURL {
    let fileName = NSProcessInfo.processInfo().globallyUniqueString
    return NSURL.fileURLWithPath(NSTemporaryDirectory().stringByAppendingPathComponent(fileName))!
  }

  static func removeFile(fileURL: NSURL) {
    let fileManager = NSFileManager.defaultManager()

    if !fileManager.fileExistsAtPath(fileURL.path!) {
      return
    }

    var error: NSError?
    let wasRemoved = fileManager.removeItemAtURL(fileURL, error: &error)
    if !wasRemoved {
      fatalError("Temp file could not be removed: \(error)")
    }
  }

  static func withTempFile<T>(block: (NSURL) -> T) -> T {
    let fileURL = tempFile()
    let result = block(fileURL)
    removeFile(fileURL)
    return result
  }
}
