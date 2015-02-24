struct ChangedRecordsResult {
  let additions: Int
  let updates: Int

  init(additions: Int = 0, updates: Int = 0) {
    self.additions = additions
    self.updates = updates
  }

  static func empty() -> ChangedRecordsResult {
    return self()
  }
}

extension ChangedRecordsResult: Printable {
  var description: String {
    var status: String

    if additions == 0 && updates == 0 {
      return "Nothing to change"
    } else {
      var additionsStatus: String
      switch additions {
      case 0:
        additionsStatus = "No additions"
      case 1:
        additionsStatus = "1 addition"
      default:
        additionsStatus = "\(additions) additions"
      }

      var updatesStatus: String
      switch updates {
      case 0:
        updatesStatus = "no updates"
      case 1:
        updatesStatus = "1 update"
      default:
        updatesStatus = "\(updates) updates"
      }

      return "\(additionsStatus), \(updatesStatus)"
    }
  }
}
