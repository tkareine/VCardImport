import Foundation

struct Files {
  static func withTempFile<T>(block: (NSURL) -> T) -> T {
    let fileName = NSProcessInfo.processInfo().globallyUniqueString
    let filePath = NSURL.fileURLWithPath(NSTemporaryDirectory().stringByAppendingPathComponent(fileName))!
    let result = block(filePath)
    removeFile(filePath)
    return result
  }

  static func removeFile(filePath: NSURL) {
    let fileManager = NSFileManager.defaultManager()

    if !fileManager.fileExistsAtPath(filePath.path!) {
      return
    }

    var error: NSError?
    let wasRemoved = fileManager.removeItemAtURL(filePath, error: &error)
    if !wasRemoved {
      fatalError("Temp file could not be removed: \(error)")
    }
  }
}
