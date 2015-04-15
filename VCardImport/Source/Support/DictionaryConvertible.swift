protocol DictionaryConvertible {
  func toDictionary() -> [String: AnyObject]

  static func fromDictionary(dictionary: [String: AnyObject]) -> Self
}
