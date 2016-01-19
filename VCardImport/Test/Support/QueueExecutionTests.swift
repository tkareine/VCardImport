import XCTest
import MiniFuture

class QueueExecutionTests: XCTestCase {
  func testDebouncer() {
    let expectation = expectationWithDescription("debouncer")
    let queue = QueueExecution.makeSerialQueue("TestDebouncer")
    var inputs: [String] = []
    let debouncer: String -> Void = QueueExecution.makeDebouncer(100, queue) { input in
      inputs.append(input)
    }

    QueueExecution.after(10, queue) { debouncer("a") }
    QueueExecution.after(10, queue) { debouncer("b") }
    QueueExecution.after(10, queue) { debouncer("c") }
    QueueExecution.after(50, queue) { debouncer("d") }
    QueueExecution.after(200, queue) { expectation.fulfill() }

    waitForExpectationsWithTimeout(1, handler: nil)
    XCTAssertEqual(inputs, ["d"])
  }

  func testSwitchToLatestFuture() {
    let expectation = expectationWithDescription("switchToLatestFuture")
    let queue = QueueExecution.makeSerialQueue("TestSwitchToLatestFuture")
    var results: [Try<String>] = []
    let switcher: Future<String> -> Void = QueueExecution.makeSwitchToLatestFuture(queue) { result in
      results.append(result)
      expectation.fulfill()
    }

    let fut0 = Future<String>.promise()
    let fut1 = Future<String>.promise()

    switcher(fut0)
    switcher(fut1)

    fut0.complete(.Success("a"))
    fut1.complete(.Success("b"))

    waitForExpectationsWithTimeout(1, handler: nil)
    XCTAssertEqual(results.count, 1)
    XCTAssertEqual(try! results.first!.value(), "b")
  }

  func testThrottler() {
    let callingThrottler = Semaphore()
    let calledThrottler = Semaphore()
    let workSimulation = Semaphore()
    var inputs: [Character] = []

    QueueExecution.async(QueueExecution.concurrentQueue) {
      let throttler: Character -> Void = QueueExecution.makeThrottler(100) { input in
        workSimulation.wait()
        inputs.append(input)
      }

      for ch in "abcde".characters {
        callingThrottler.wait()
        throttler(ch)
        calledThrottler.signal()
      }
    }

    XCTAssertEqual(inputs, [])

    callingThrottler.signal()
    workSimulation.signal()
    calledThrottler.wait()

    XCTAssertEqual(inputs, ["a"])

    callingThrottler.signal()
    calledThrottler.wait()

    XCTAssertEqual(inputs, ["a"])

    NSThread.sleepForTimeInterval(0.2)
    callingThrottler.signal()
    workSimulation.signal()
    calledThrottler.wait()

    XCTAssertEqual(inputs, ["a", "c"])

    // throttling wait time gets marked after completing the block

    NSThread.sleepForTimeInterval(0.2)
    callingThrottler.signal()
    NSThread.sleepForTimeInterval(0.2)
    workSimulation.signal()
    calledThrottler.wait()

    XCTAssertEqual(inputs, ["a", "c", "d"])

    callingThrottler.signal()
    calledThrottler.wait()

    XCTAssertEqual(inputs, ["a", "c", "d"])
  }
}
