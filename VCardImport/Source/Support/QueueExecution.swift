import Dispatch

struct QueueExecution {
  typealias OnceToken = dispatch_once_t
  typealias Queue = dispatch_queue_t

  static let concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
  static let mainQueue = dispatch_get_main_queue()

  static func makeSerialQueue(id: String) -> Queue {
    return dispatch_queue_create("\(Config.BundleIdentifier).\(id)", DISPATCH_QUEUE_SERIAL)
  }

  static func sync(queue: Queue, block: () -> Void) {
    dispatch_sync(queue, block)
  }

  static func async(queue: Queue, block: () -> Void) {
    dispatch_async(queue, block)
  }

  static func after(delayInMS: Int, _ queue: Queue, block: () -> Void) {
    let delayInNS = Int64(delayInMS) * Int64(NSEC_PER_MSEC)
    let scheduleAt = dispatch_time(DISPATCH_TIME_NOW, delayInNS)
    dispatch_after(scheduleAt, queue) {
      block()
    }
  }

  static func once(inout token: OnceToken, block: () -> Void) {
    dispatch_once(&token, block)
  }

  /**
   * :param: queue The queue in which to execute. Must be a serial queue.
   */
  static func makeDebouncer<T>(
    waitInMS: Int,
    _ queue: Queue,
    block: (T -> Void))
    -> (T -> Void)
  {
    var lastDelayId: UInt64 = 0

    func later(input: T) {
      lastDelayId = lastDelayId &+ 1
      let currentDelayId = lastDelayId
      after(waitInMS, queue) {
        if lastDelayId == currentDelayId {
          block(input)
        }
      }
    }

    return later
  }
}
