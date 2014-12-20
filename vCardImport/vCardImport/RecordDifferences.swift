import Foundation
import AddressBook

struct RecordDifferences {
  let additions: [ABRecord]
  let changes: [RecordChangeSet]

  static func resolveBetween(
    #oldRecords: [ABRecord],
    newRecords: [ABRecord])
    -> RecordDifferences
  {
    let (additions, matches) = findAdditionsAndExistingMatchesBetween(oldRecords, newRecords)
    let changes = findChanges(matches)
    return RecordDifferences(additions: additions, changes: changes)
  }

  private static func findAdditionsAndExistingMatchesBetween(
    oldRecords: [ABRecord],
    _ newRecords: [ABRecord])
    -> ([ABRecord], [String: (ABRecord, ABRecord)])
  {
    var additions: [ABRecord] = []
    var matchingRecordsByName: [String: (ABRecord, ABRecord)] = [:]

    for newRecord in newRecords {
      let newRecordName = self.recordNameOf(newRecord)
      let existingRecordsWithName = oldRecords.filter { self.recordNameOf($0) == newRecordName }

      switch existingRecordsWithName.count {
      case 0:
        additions.append(newRecord)
      case 1:
        let existingRecord: ABRecord = existingRecordsWithName.first!
        matchingRecordsByName[newRecordName] = (existingRecord, newRecord)
      default:
        NSLog("Skipping updating contact having multiple records with the same name: %@", newRecordName)
      }
    }

    return (additions, matchingRecordsByName)
  }

  private static func findChanges(
    matchingRecords: [String: (ABRecord, ABRecord)])
    -> [RecordChangeSet]
  {
    var changeSets: [RecordChangeSet] = []

    for (name, (existingRecord, newRecord)) in matchingRecords {
      let changeSet = RecordChangeSet(oldRecord: existingRecord, newRecord: newRecord)
      if let cs = changeSet {
        changeSets.append(cs)
      }
    }

    return changeSets
  }

  private static func recordNameOf(record: ABRecord) -> String {
    return ABRecordCopyCompositeName(record).takeRetainedValue()
  }
}
