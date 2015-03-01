import MiniFuture
import XCTest

class MiniFutureExtensionTests: XCTestCase {
  func testSwitchLatest() {
    let fut0 = Future<String>.promise()
    let fut1 = Future<String>.promise()

    let switcher = Future<String>.makeSwitchLatest()

    let swi0 = switcher(fut0)
    let swi1 = switcher(fut1)

    fut0.complete(.Success("a"))
    fut1.complete(.Success("b"))

    XCTAssert(swi1.get() == .Success("b"))
    XCTAssertFalse(swi0.isCompleted)
  }
}
