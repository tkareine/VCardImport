import Dispatch

struct BackgroundExecution {
  static var sharedQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

  static func dispatchAsync(block: () -> Void) {
    dispatch_async(sharedQueue, block)
  }

  static func dispatchAsyncToMain(block: () -> Void) {
    dispatch_async(dispatch_get_main_queue(), block)
  }
}
