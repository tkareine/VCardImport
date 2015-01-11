import XCTest

class InsertionOrderDictionaryTests: XCTestCase {
  func testEmpty() {
    var dict: InsertionOrderDictionary<String, Int> = InsertionOrderDictionary()

    XCTAssertTrue(dict.isEmpty)
    XCTAssertEqual(dict.count, 0)
    XCTAssertEqual(dict.description, "[]")
    XCTAssertEqual(dict.keys, [])
    XCTAssertEqual(dict.values, [])
  }

  func testAdd() {
    var dict: InsertionOrderDictionary<String, Int> = InsertionOrderDictionary()
    dict["a"] = 0
    dict["b"] = 1

    XCTAssertFalse(dict.isEmpty)
    XCTAssertEqual(dict.count, 2)
    XCTAssertEqual(dict.description, "[a: 0, b: 1]")
    XCTAssertEqual(dict.keys, ["a", "b"])
    XCTAssertEqual(dict.values, [0, 1])
    XCTAssertEqual(dict["a"]!, 0)
    XCTAssertEqual(dict[0], 0)
    XCTAssertEqual(dict["b"]!, 1)
    XCTAssertEqual(dict[1], 1)
  }

  func testModify() {
    var dict: InsertionOrderDictionary<String, Int> = InsertionOrderDictionary()
    dict["a"] = 0
    dict["b"] = 1
    dict[1] = 11
    dict[0] = 10

    XCTAssertEqual(dict.count, 2)
    XCTAssertEqual(dict["a"]!, 10)
    XCTAssertEqual(dict["b"]!, 11)
  }

  func testRemove() {
    var dict: InsertionOrderDictionary<String, Int> = InsertionOrderDictionary()
    dict["a"] = 0
    dict["b"] = 1

    XCTAssertEqual(dict["a"]!, 0)

    let r0 = dict.removeValueAtIndex(0)

    XCTAssertEqual(r0!, 0)
    XCTAssertEqual(dict.count, 1)
    XCTAssert(dict["a"] == nil)
    XCTAssertEqual(dict[0], 1)
    XCTAssertEqual(dict["b"]!, 1)

    let r1 = dict.removeValueForKey("a")

    XCTAssert(r1 == nil)

    let r2 = dict.removeValueForKey("b")

    XCTAssertEqual(r2!, 1)
    XCTAssertTrue(dict.isEmpty)
    XCTAssert(dict["b"] == nil)
  }

  func testGenerate() {
    var dict: InsertionOrderDictionary<String, Int> = InsertionOrderDictionary()
    dict["a"] = 0
    dict["b"] = 1
    dict["c"] = 2

    var gen0 = dict.generate()
    let t0_0 = gen0.next()!

    XCTAssertEqual(t0_0.0, "a")
    XCTAssertEqual(t0_0.1, 0)

    dict.removeValueAtIndex(1)
    dict["c"] = 3

    let t0_1 = gen0.next()!
    var gen1 = dict.generate()
    let t1_0 = gen1.next()!

    XCTAssertEqual(t0_1.0, "b")
    XCTAssertEqual(t0_1.1, 1)
    XCTAssertEqual(t1_0.0, "a")
    XCTAssertEqual(t1_0.1, 0)

    let t0_2 = gen0.next()!
    let t1_1 = gen1.next()!

    XCTAssertEqual(t0_2.0, "c")
    XCTAssertEqual(t0_2.1, 2)
    XCTAssertEqual(t1_1.0, "c")
    XCTAssertEqual(t1_1.1, 3)

    let t0_3 = gen0.next()
    let t1_2 = gen1.next()

    XCTAssert(t0_3 == nil)
    XCTAssert(t1_2 == nil)
  }

  func testLiteral() {
    let dict: InsertionOrderDictionary<String, Int> = ["a": 0, "b": 1, "c": 2, "d": 3]
    XCTAssertEqual(dict.description, "[a: 0, b: 1, c: 2, d: 3]")
  }

  func testIndexOf() {
    var dict: InsertionOrderDictionary<String, Float> = ["a": 3.14, "b": 42.0]
    XCTAssertEqual(dict.indexOf("a")!, 0)
    XCTAssertEqual(dict.indexOf("b")!, 1)
    XCTAssert(dict.indexOf("c") == nil)
  }

  func testMove() {
    var dict0: InsertionOrderDictionary<String, Int> = ["a": 0, "b": 1]
    dict0.move(fromIndex: 1, toIndex: 1)
    XCTAssertEqual(dict0.description, "[a: 0, b: 1]")

    var dict1: InsertionOrderDictionary<String, Int> = ["a": 0, "b": 1, "c": 2]
    dict1.move(fromIndex: 2, toIndex: 0)
    XCTAssertEqual(dict1.description, "[c: 2, a: 0, b: 1]")
  }
}
