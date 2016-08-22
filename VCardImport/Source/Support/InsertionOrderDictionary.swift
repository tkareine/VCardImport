struct InsertionOrderDictionary<Key: Hashable, Value> {
  private var keyOrder: [Key]
  private var dictionary: [Key: Value]

  init() {
    keyOrder = []
    dictionary = [:]
  }

  var keys: [Key] {
    return keyOrder
  }

  var values: [Value] {
    var result = [Value]()
    for key in keyOrder {
      result.append(dictionary[key]!)
    }
    return result
  }

  func get(key: Key) -> Value? {
    return dictionary[key]
  }

  mutating func put(key: Key, to value: Value) {
    if !hasKey(key) {
      keyOrder.append(key)
    }
    dictionary[key] = value
  }

  mutating func removeValueForKey(key: Key) -> Value? {
    if hasKey(key) {
      let index = keyOrder.indexOf(key)!
      return remove(index, key)
    } else {
      return nil
    }
  }

  mutating func removeValueAtIndex(index: Int) -> Value? {
    if index < keyOrder.count {
      let key = keyOrder[index]
      return remove(index, key)
    } else {
      return nil
    }
  }

  private mutating func remove(index: Int, _ key: Key) -> Value {
    keyOrder.removeAtIndex(index)
    return dictionary.removeValueForKey(key)!
  }

  mutating func move(fromIndex fromIndex: Int, toIndex: Int) {
    if fromIndex == toIndex {
      return
    }

    let key = keyOrder.removeAtIndex(fromIndex)
    keyOrder.insert(key, atIndex: toIndex)
  }

  func hasKey(key: Key) -> Bool {
    return get(key) != nil
  }

  func indexOf(key: Key) -> Int? {
    return keyOrder.indexOf(key)
  }
}

struct InsertionOrderDictionaryGenerator<Key: Hashable, Value>: GeneratorType {
  private let keyOrder: [Key]
  private let dictionary: [Key: Value]
  private var index: Int = 0

  typealias Element = (Key, Value)

  init(keyOrder: [Key], dictionary: [Key: Value]) {
    self.keyOrder = keyOrder
    self.dictionary = dictionary
  }

  mutating func next() -> (Key, Value)? {
    guard index < keyOrder.endIndex else {
      return nil
    }

    let key = keyOrder[index]
    let value = dictionary[key]!
    index += 1
    return (key, value)
  }
}

extension InsertionOrderDictionary: MutableCollectionType {
  typealias Generator = InsertionOrderDictionaryGenerator<Key, Value>
  typealias Index = Int

  func generate() -> Generator {
    return InsertionOrderDictionaryGenerator(
      keyOrder: keyOrder,
      dictionary: dictionary)
  }

  var startIndex: Int {
    return keyOrder.startIndex
  }

  var endIndex: Int {
    return keyOrder.endIndex
  }

  subscript(index: Int) -> (Key, Value) {
    get {
      let key = keyOrder[index]
      return (key, dictionary[key]!)
    }

    set {
      let oldKey = keyOrder[index]

      dictionary.removeValueForKey(oldKey)

      let newKey = newValue.0

      keyOrder[index] = newKey
      dictionary[newKey] = newValue.1
    }
  }
}

extension InsertionOrderDictionary: DictionaryLiteralConvertible {
  init(dictionaryLiteral elements: (Key, Value)...) {
    self.init()
    for (key, value) in elements {
      put(key, to: value)
    }
  }
}

extension InsertionOrderDictionary: CustomStringConvertible, CustomDebugStringConvertible {
  var description: String {
    return describeWith { key, value in "\(key): \(value)" }
  }

  var debugDescription: String {
    return describeWith { key, value in "\(String(reflecting: key)): \(String(reflecting: value))" }
  }

  private func describeWith(@noescape pairDescriber: (Key, Value) -> String) -> String {
    func join(pairs: [String]) -> String {
      let joined = pairs.joinWithSeparator(", ")
      return "[" + joined + "]"
    }

    return join(map(pairDescriber))
  }
}
