import Foundation

struct VCardSource {
  let name: String
  let connection: Connection

  struct Connection {
    let url: String
  }
}
