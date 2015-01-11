struct InsertionOrderDictionary<K: Hashable, V> {
  private var keyOrder: [K] = []
  private var dictionary: [K: V] = [:]

  init() {}

  var isEmpty: Bool {
    return keyOrder.isEmpty
  }

  var count: Int {
    return keyOrder.count
  }

  var keys: [K] {
    return keyOrder
  }

  var values: [V] {
    return Array(self).map { $1 }
  }

  subscript(key: K) -> V? {
    get {
      return dictionary[key]
    }

    set {
      if let existing = dictionary[key] {
        dictionary[key] = newValue
      } else {
        keyOrder.append(key)
        dictionary[key] = newValue
      }
    }
  }

  subscript(index: Int) -> V {
    get {
      let key = keyOrder[index]
      return dictionary[key]!
    }

    set {
      let key = keyOrder[index]
      dictionary[key] = newValue
    }
  }

  mutating func removeValueForKey(key: K) -> V? {
    if let value = dictionary[key] {
      let index = find(keyOrder, key)!
      return remove(index, key)
    } else {
      return nil
    }
  }

  mutating func removeValueAtIndex(index: Int) -> V? {
    if index < keyOrder.count {
      let key = keyOrder[index]
      return remove(index, key)
    } else {
      return nil
    }
  }

  private mutating func remove(index: Int, _ key: K) -> V {
    keyOrder.removeAtIndex(index)
    return dictionary.removeValueForKey(key)!
  }

  mutating func move(#fromIndex: Int, toIndex: Int) {
    if fromIndex == toIndex {
      return
    }

    let key = keyOrder.removeAtIndex(fromIndex)
    keyOrder.insert(key, atIndex: toIndex)
  }

  func indexOf(key: K) -> Int? {
    return find(keyOrder, key)
  }
}

struct InsertionOrderDictionaryGenerator<K: Hashable, V>: GeneratorType {
  private var keyOrder: [K]
  private var dictionary: [K: V]

  typealias Element = (K, V)

  mutating func next() -> Element? {
    if keyOrder.isEmpty {
      return nil
    }
    let key = keyOrder[0]
    let value = dictionary[key]!
    keyOrder = Array(keyOrder[1..<keyOrder.count])
    dictionary.removeValueForKey(key)
    return (key, value)
  }
}

extension InsertionOrderDictionary: SequenceType {
  typealias Generator = InsertionOrderDictionaryGenerator<K, V>

  func generate() -> Generator {
    return InsertionOrderDictionaryGenerator(
      keyOrder: keyOrder,
      dictionary: dictionary)
  }
}

extension InsertionOrderDictionary: DictionaryLiteralConvertible {
  typealias Key = K
  typealias Value = V

  init(dictionaryLiteral elements: (Key, Value)...) {
    for (key, value) in elements {
      keyOrder.append(key)
      dictionary[key] = value
    }
  }
}

extension InsertionOrderDictionary: Printable {
  var description: String {
    return join(map(self) { k, v in "\(k): \(v)" })
  }

  private func join(pairs: [String]) -> String {
    let joined = ", ".join(pairs)
    return "[" + joined + "]"
  }
}
