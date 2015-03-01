import XCTest

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
}
