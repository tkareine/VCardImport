import Foundation

struct JSONSerialization {
  static func encode(obj: AnyObject) -> NSData {
    do {
      return try NSJSONSerialization.dataWithJSONObject(obj, options: [])
    } catch {
      fatalError("JSON serialization failed: \(error)")
    }
  }

  static func decode(data: NSData) -> AnyObject {
    do {
      return try NSJSONSerialization.JSONObjectWithData(data, options: [])
    } catch {
      fatalError("JSON deserialization failed: \(error)")
    }
  }
}
