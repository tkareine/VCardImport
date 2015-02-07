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
    let (additions, matches) = findAdditionsAndExistingMatchesBetween(
      oldRecords,
      uniqueRecordsOf(newRecords))
    let changes = findChanges(matches)
    return self(additions: additions, changes: changes)
  }

  private static func uniqueRecordsOf(records: [ABRecord]) -> [RecordName: ABRecord] {
    var uniqueRecords: [RecordName: ABRecord] = [:]
    var skipRecords: [RecordName: Bool] = [:]
    for rec in records {
      if let name = RecordName.of(rec) {
        if uniqueRecords.hasKey(name) {
          uniqueRecords.removeValueForKey(name)
          skipRecords[name] = true
        } else if !skipRecords.hasKey(name) {
          uniqueRecords[name] = rec
        }
      }
    }
    return uniqueRecords
  }

  private static func findAdditionsAndExistingMatchesBetween(
    oldRecords: [ABRecord],
    _ newRecords: [RecordName: ABRecord])
    -> ([ABRecord], [RecordName: (ABRecord, ABRecord)])
  {
    var additions: [ABRecord] = []
    var matchingRecordsByName: [RecordName: (ABRecord, ABRecord)] = [:]

    for (newRecordName, newRecord) in newRecords {
      let existingRecordsWithName = oldRecords.filter { oldRecord in
        if let oldRecordName = RecordName.of(oldRecord) {
          return oldRecordName == newRecordName
        } else {
          return false
        }
      }

      switch existingRecordsWithName.count {
      case 0:
        NSLog("Marking record for addition: %@", newRecordName.description)
        additions.append(newRecord)
      case 1:
        NSLog("Marking record for checking changes: %@", newRecordName.description)
        let existingRecord: ABRecord = existingRecordsWithName.first!
        matchingRecordsByName[newRecordName] = (existingRecord, newRecord)
      default:
        NSLog("Skipping update for multiple existing records having same name: %@", newRecordName.description)
      }
    }

    return (additions, matchingRecordsByName)
  }

  private static func findChanges(
    matchingRecords: [RecordName: (ABRecord, ABRecord)])
    -> [RecordChangeSet]
  {
    var changeSets: [RecordChangeSet] = []

    for (recordName, (existingRecord, newRecord)) in matchingRecords {
      let changeSet = RecordChangeSet(oldRecord: existingRecord, newRecord: newRecord)
      if let cs = changeSet {
        NSLog("Marking record for having changes: %@", recordName.description)
        changeSets.append(cs)
      }
    }

    return changeSets
  }
}
