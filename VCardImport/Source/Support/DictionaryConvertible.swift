protocol DictionaryConvertible {
  func toDictionary() -> [String: AnyObject]

  class func fromDictionary(dictionary: [String: AnyObject]) -> Self
}
