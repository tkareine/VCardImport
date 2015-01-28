import Foundation

struct JSONSerialization {
  static func encode(obj: AnyObject) -> NSData {
    var err: NSError?
    if let data = NSJSONSerialization.dataWithJSONObject(obj, options: nil, error: &err) {
      return data
    } else {
      fatalError("JSON serialization failed: \(err!)")
    }
  }

  static func decode(data: NSData) -> AnyObject {
    var err: NSError?
    if let obj: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &err) {
      return obj
    } else {
      fatalError("JSON deserialization failed: \(err!)")
    }
  }
}
