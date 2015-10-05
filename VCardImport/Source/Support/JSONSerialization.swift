import Foundation

struct JSONSerialization {
  static func encode(obj: AnyObject) -> NSData {
    var err: NSError?
    do {
      let data = try NSJSONSerialization.dataWithJSONObject(obj, options: [])
      return data
    } catch let error as NSError {
      err = error
      fatalError("JSON serialization failed: \(err!)")
    }
  }

  static func decode(data: NSData) -> AnyObject {
    var err: NSError?
    do {
      let obj: AnyObject = try NSJSONSerialization.JSONObjectWithData(data, options: [])
      return obj
    } catch let error as NSError {
      err = error
      fatalError("JSON deserialization failed: \(err!)")
    }
  }
}
