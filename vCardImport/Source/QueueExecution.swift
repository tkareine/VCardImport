import Dispatch

struct QueueExecution {
  static var backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

  static func toBackgroundAsync(block: () -> Void) {
    dispatch_async(backgroundQueue, block)
  }

  static func toMainAsync(block: () -> Void) {
    dispatch_async(dispatch_get_main_queue(), block)
  }

  static func toMainAfter(delayInMS: Int, block: () -> Void) {
    let delayInNS = Int64(delayInMS) * Int64(NSEC_PER_MSEC)
    let scheduleAt = dispatch_time(DISPATCH_TIME_NOW, delayInNS)
    dispatch_after(scheduleAt, dispatch_get_main_queue(), block)
  }
}
