import Foundation

extension Dictionary {
  var first: (Key, Value)? {
    var gen = self.generate()
    return gen.next()
  }

  func hasKey(key: Key) -> Bool {
    return self[key] != nil
  }
}

private let WhiteSpaceAndNewlineCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()

extension String {
  func trim() -> String {
    return stringByTrimmingCharactersInSet(WhiteSpaceAndNewlineCharacterSet)
  }
}

private let ISODateFormatter: NSDateFormatter = {
  let formatter = NSDateFormatter()
  formatter.timeZone = NSTimeZone(abbreviation: "GMT")
  formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
  return formatter
}()

private let LocaleMediumDateFormatter: NSDateFormatter = {
  let formatter = NSDateFormatter()
  formatter.dateStyle = .MediumStyle
  formatter.timeStyle = .ShortStyle
  return formatter
}()

extension NSDate {
  var localeMediumString: NSString {
    return LocaleMediumDateFormatter.stringFromDate(self)
  }

  var ISOString: NSString {
    return ISODateFormatter.stringFromDate(self)
  }

  class func dateFromISOString(string: String) -> NSDate? {
    return ISODateFormatter.dateFromString(string)
  }
}

func ==<T: Equatable>(lhs: (T, T), rhs: (T, T)) -> Bool {
  return (lhs.0 == rhs.0) && (lhs.1 == rhs.1)
}

func !=<T: Equatable>(lhs: (T, T), rhs: (T, T)) -> Bool {
  return !(lhs == rhs)
}

func countWhere<S: SequenceType>(seq: S, predicate: (S.Generator.Element -> Bool)) -> Int {
  var c = 0
  for e in seq {
    if predicate(e) {
      c += 1
    }
  }
  return c
}
