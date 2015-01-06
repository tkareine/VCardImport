import Dispatch

struct QueueExecution {
  static let backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
  static let mainQueue = dispatch_get_main_queue()

  static func async(queue: dispatch_queue_t, block: () -> Void) {
    dispatch_async(queue, block)
  }

  static func after(
    delayInMS: Int,
    _ queue: dispatch_queue_t,
    block: () -> Void)
  {
    let delayInNS = Int64(delayInMS) * Int64(NSEC_PER_MSEC)
    let scheduleAt = dispatch_time(DISPATCH_TIME_NOW, delayInNS)
    dispatch_after(scheduleAt, queue, block)
  }
}
