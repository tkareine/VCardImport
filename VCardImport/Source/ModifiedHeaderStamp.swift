import Foundation

struct ModifiedHeaderStamp {
  private static let HeadersToSearch = ["Last-Modified", "ETag"]

  let name: String
  let value: String

  init(name: String, value: String) {
    self.name = name
    self.value = value
  }

  init?(headers: [NSObject: AnyObject]) {
    func findNameAndValue() -> (String, String)? {
      for candidateName in ModifiedHeaderStamp.HeadersToSearch {
        if let candidateValue = (headers[candidateName] as? String)?.trim() {
          if !candidateValue.isEmpty {
            return (candidateName, candidateValue)
          }
        }
      }
      return nil
    }

    if let (name, value) = findNameAndValue() {
      self.name = name
      self.value = value
    } else {
      return nil
    }
  }
}

extension ModifiedHeaderStamp: DictionaryConvertible {
  func toDictionary() -> [String: AnyObject] {
    return [
      "name": name,
      "value": value
    ]
  }

  static func fromDictionary(dictionary: [String: AnyObject]) -> ModifiedHeaderStamp {
    return self(
      name: dictionary["name"] as String!,
      value: dictionary["value"] as String!)
  }
}

extension ModifiedHeaderStamp: Equatable {}

func ==(lhs: ModifiedHeaderStamp, rhs: ModifiedHeaderStamp) -> Bool {
  return lhs.name == rhs.name && lhs.value == rhs.value
}

extension ModifiedHeaderStamp: Printable {
  var description: String {
    return "\(name): \(value)"
  }
}
