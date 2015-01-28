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
  var capitalized: String {
    if let head = first(self) {
      let tail = dropFirst(self)
      return String(head).uppercaseString + tail
    } else {
      return self
    }
  }

  var trimmed: String {
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

// adapted and modified from https://gist.github.com/dperini/729294
/* Regular expression for validating HTTP(S) URLs, modified from
 * Diego Perini's regular expression at
 * <https://gist.github.com/dperini/729294>.
 *
 * Author: Diego Perini
 * Updated: 2010/12/05
 * License: MIT
 *
 * Copyright (c) 2010-2013 Diego Perini (http://www.iport.it)
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */
private let HTTPURLRegexp = "^" +
  // protocol identifier
  "(?:https?://)" +
  "(?:" +
    // IP address dotted notation octets
    // excludes reserved space >= 224.0.0.0
    // excludes network & broadcast addresses
    // (first & last IP address of each class)
    "(?:[0-9]\\d?|1\\d\\d|2[01]\\d|22[0-3])" +
    "(?:\\.(?:0|1?\\d{1,2}|2[0-4]\\d|25[0-5])){2}" +
    "(?:\\.(?:[0-9]\\d?|1\\d\\d|2[0-4]\\d|25[0-4]))" +
    "|" +
    // host name
    "(?:(?:[a-z\\u00a1-\\uffff0-9]-*)*[a-z\\u00a1-\\uffff0-9]+)" +
    // domain name
    "(?:\\.(?:[a-z\\u00a1-\\uffff0-9]-*)*[a-z\\u00a1-\\uffff0-9]+)*" +
    // TLD identifier
    "(?:\\.(?:[a-z\\u00a1-\\uffff]{2,}))?" +
  ")" +
  // port number
  "(?::\\d{2,5})?" +
  // resource path
  "(?:/[^\\s]*)?" +
  "$"

let HTTPURLRegexpPredicate = NSPredicate(format: "SELF MATCHES[cd] %@", HTTPURLRegexp)!

extension NSURL {
  var isValidHTTPURL: Bool {
    if let url = absoluteString {
      return HTTPURLRegexpPredicate.evaluateWithObject(url)
    } else {
      return false
    }
  }
}

func ==<T: Equatable>(lhs: (T, T), rhs: (T, T)) -> Bool {
  return (lhs.0 == rhs.0) && (lhs.1 == rhs.1)
}

func !=<T: Equatable>(lhs: (T, T), rhs: (T, T)) -> Bool {
  return !(lhs == rhs)
}

func countWhere<S: SequenceType, E where E == S.Generator.Element>(
  seq: S,
  predicate: E -> Bool)
  -> Int
{
  var c = 0
  for e in seq {
    if predicate(e) {
      c += 1
    }
  }
  return c
}

func findElement<S: SequenceType, E where E == S.Generator.Element>(
  seq: S,
  predicate: E -> Bool)
  -> E?
{
  for e in seq {
    if predicate(e) {
      return e
    }
  }
  return nil
}

func findIndex<S: SequenceType, E where E == S.Generator.Element>(
  seq: S,
  predicate: E -> Bool)
  -> Int?
{
  for (idx, e) in enumerate(seq) {
    if predicate(e) {
      return idx
    }
  }
  return nil
}
