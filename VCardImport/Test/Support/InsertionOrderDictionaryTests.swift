import XCTest

class InsertionOrderDictionaryTests: XCTestCase {
  func testEmpty() {
    let dict: InsertionOrderDictionary<String, Int> = InsertionOrderDictionary()

    XCTAssertTrue(dict.isEmpty)
    XCTAssertEqual(dict.count, 0)
    XCTAssertEqual(dict.description, "[]")
    XCTAssertEqual(dict.debugDescription, "[]")
    XCTAssertEqual(dict.keys, [])
    XCTAssertEqual(dict.values, [])
    XCTAssertNil(dict.get("nosuch"))
  }

  func testPut() {
    var dict: InsertionOrderDictionary<String, Int> = InsertionOrderDictionary()
    dict.put("a", to: 40)
    dict.put("b", to: 41)

    XCTAssertFalse(dict.isEmpty)
    XCTAssertEqual(dict.count, 2)
    XCTAssertEqual(dict.description, "[a: 40, b: 41]")
    XCTAssertEqual(dict.debugDescription, "[\"a\": 40, \"b\": 41]")
    XCTAssertEqual(dict.keys, ["a", "b"])
    XCTAssertEqual(dict.values, [40, 41])
    XCTAssertEqual(dict.get("a"), 40)
    XCTAssert(dict[0] == ("a", 40))
    XCTAssertEqual(dict.get("b"), 41)
    XCTAssert(dict[1] == ("b", 41))
  }

  func testModify() {
    var dict: InsertionOrderDictionary<String, Int> = InsertionOrderDictionary()
    dict.put("a", to: 30)
    dict.put("b", to: 31)
    dict[1] = ("A", 40)
    dict[0] = ("B", 41)

    XCTAssertEqual(dict.count, 2)
    XCTAssert(dict[0] == ("B", 41))
    XCTAssert(dict[1] == ("A", 40))

    dict.put("A", to: 50)

    XCTAssertEqual(dict.count, 2)
    XCTAssert(dict[0] == ("B", 41))
    XCTAssert(dict[1] == ("A", 50))
  }

  func testRemove() {
    var dict: InsertionOrderDictionary<String, Int> = InsertionOrderDictionary()
    dict.put("a", to: 40)
    dict.put("b", to: 41)

    XCTAssert(dict[0] == ("a", 40))
    XCTAssertEqual(dict.get("a"), 40)

    let r0 = dict.removeValueAtIndex(0)

    XCTAssertEqual(r0, 40)
    XCTAssertEqual(dict.count, 1)
    XCTAssertNil(dict.get("a"))
    XCTAssert(dict[0] == ("b", 41))
    XCTAssertEqual(dict.get("b"), 41)

    let r1 = dict.removeValueForKey("a")

    XCTAssertNil(r1)

    let r2 = dict.removeValueForKey("b")

    XCTAssertEqual(r2, 41)
    XCTAssertTrue(dict.isEmpty)
    XCTAssertNil(dict.get("b"))
  }

  func testGenerate() {
    var dict: InsertionOrderDictionary<String, Int> = InsertionOrderDictionary()
    dict.put("a", to: 40)
    dict.put("b", to: 41)
    dict.put("c", to: 42)

    var gen0 = dict.generate()
    let t0_0 = gen0.next()!

    XCTAssertEqual(t0_0.0, "a")
    XCTAssertEqual(t0_0.1, 40)

    dict.removeValueForKey("b")
    dict.put("c", to: 52)

    let t0_1 = gen0.next()!
    var gen1 = dict.generate()
    let t1_0 = gen1.next()!

    XCTAssertEqual(t0_1.0, "b")
    XCTAssertEqual(t0_1.1, 41)
    XCTAssertEqual(t1_0.0, "a")
    XCTAssertEqual(t1_0.1, 40)

    let t0_2 = gen0.next()!
    let t1_1 = gen1.next()!

    XCTAssertEqual(t0_2.0, "c")
    XCTAssertEqual(t0_2.1, 42)
    XCTAssertEqual(t1_1.0, "c")
    XCTAssertEqual(t1_1.1, 52)

    let t0_3 = gen0.next()
    let t1_2 = gen1.next()

    XCTAssertNil(t0_3)
    XCTAssertNil(t1_2)
  }

  func testForLoopSyntax() {
    var dict: InsertionOrderDictionary<String, Int> = InsertionOrderDictionary()
    dict.put("a", to: 40)
    dict.put("b", to: 41)
    dict.put("c", to: 42)

    var result = [(String, Int)]()

    for kv in dict {
      result.append(kv)
    }

    XCTAssertEqual(result.count, 3)
    XCTAssert(result[0] == ("a", 40))
    XCTAssert(result[1] == ("b", 41))
    XCTAssert(result[2] == ("c", 42))
  }

  func testLiteralPreservesLastValueOfDuplicateKey() {
    let dict: InsertionOrderDictionary<String, Int> = ["a": 40, "b": 41, "c": 42, "b": 51]
    XCTAssertEqual(dict.count, 3)
    XCTAssert(dict[0] == ("a", 40))
    XCTAssert(dict[1] == ("b", 51))
    XCTAssert(dict[2] == ("c", 42))
  }

  func testHasKey() {
    let dict: InsertionOrderDictionary<String, Float> = ["a": 3.14]
    XCTAssertTrue(dict.hasKey("a"))
    XCTAssertFalse(dict.hasKey("b"))
  }

  func testIndexOf() {
    let dict: InsertionOrderDictionary<String, Float> = ["a": 3.14, "b": 42]
    XCTAssertEqual(dict.indexOf("a"), 0)
    XCTAssertEqual(dict.indexOf("b"), 1)
    XCTAssertNil(dict.indexOf("c"))
  }

  func testMove() {
    var dict0: InsertionOrderDictionary<String, Int> = ["a": 40, "b": 41]
    dict0.move(fromIndex: 1, toIndex: 1)
    XCTAssertEqual(dict0.description, "[a: 40, b: 41]")

    var dict1: InsertionOrderDictionary<String, Int> = ["a": 40, "b": 41, "c": 42]
    dict1.move(fromIndex: 2, toIndex: 0)
    XCTAssertEqual(dict1.description, "[c: 42, a: 40, b: 41]")
  }
}
