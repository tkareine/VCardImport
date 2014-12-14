import Foundation

extension Array {
  typealias Predicate = T -> Bool

  func countWhere(predicate: Predicate) -> Int {
    var c = 0
    for e in self {
      if predicate(e) {
        c += 1
      }
    }
    return c
  }

  func find(predicate: Predicate) -> T? {
    for e in self {
      if predicate(e) {
        return e
      }
    }
    return nil
  }

  func any(predicate: Predicate) -> Bool {
    return find(predicate) != nil
  }
}

func ==<T: Equatable>(lhs: (T, T), rhs: (T, T)) -> Bool {
  return (lhs.0 == rhs.0) && (lhs.1 == rhs.1)
}

func !=<T: Equatable>(lhs: (T, T), rhs: (T, T)) -> Bool {
  return !(lhs == rhs)
}
