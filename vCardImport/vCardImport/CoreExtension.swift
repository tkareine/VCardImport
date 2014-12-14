import Foundation

extension Array {
  func countWhere(predicate: T -> Bool) -> Int {
    var c = 0
    for e in self {
      if predicate(e) {
        c += 1
      }
    }
    return c
  }

  func find(predicate: T -> Bool) -> T? {
    for e in self {
      if predicate(e) {
        return e
      }
    }
    return nil
  }

  func any(predicate: T -> Bool) -> Bool {
    return find(predicate) != nil
  }
}

func ==<T: Equatable>(lhs: (T, T), rhs: (T, T)) -> Bool {
  return (lhs.0 == rhs.0) && (lhs.1 == rhs.1)
}

func !=<T: Equatable>(lhs: (T, T), rhs: (T, T)) -> Bool {
  return !(lhs == rhs)
}
