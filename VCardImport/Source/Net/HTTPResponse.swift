struct HTTPResponse {
  private static let SuccessStatusCodes = 200..<300

  static func isSuccessStatusCode(code: Int) -> Bool {
    return SuccessStatusCodes.contains(code)
  }
}
