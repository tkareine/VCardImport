protocol DictionaryConvertible {
  typealias DictionaryType

  func toDictionary() -> [String: AnyObject]

  class func fromDictionary(dictionary: [String: AnyObject]) -> DictionaryType
}
