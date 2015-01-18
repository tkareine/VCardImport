import XCTest

class QueueExecutionTests: XCTestCase {
  func testDebouncer() {
    let expectation = expectationWithDescription("debouncer")
    let queue = dispatch_queue_create("test debouncer", DISPATCH_QUEUE_SERIAL)
    var inputs: [String] = []
    let debouncer: String -> Void = QueueExecution.makeDebouncer(100, queue) { input in
      inputs.append(input)
    }

    QueueExecution.after(10, queue) { debouncer("a") }
    QueueExecution.after(10, queue) { debouncer("b") }
    QueueExecution.after(10, queue) { debouncer("c") }
    QueueExecution.after(50, queue) { debouncer("d") }
    QueueExecution.after(200, queue) { expectation.fulfill() }

    waitForExpectationsWithTimeout(250, handler: nil)
    XCTAssertEqual(inputs, ["d"])
  }

  func testSwitchLatest() {
    let fut0 = Future<String>.promise()
    let fut1 = Future<String>.promise()

    let switcher: Future<String> -> Future<String> = QueueExecution.makeSwitchLatest()

    let swi0 = switcher(fut0)
    let swi1 = switcher(fut1)

    fut0.complete(.Success("a"))
    fut1.complete(.Success("b"))

    XCTAssert(swi1.get() == .Success("b"))
    XCTAssertFalse(swi0.isCompleted)
  }
}
