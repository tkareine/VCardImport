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
    -> ([ABRecord], [RecordName: (ABRecord, ABRecord)])
  {
    var additions: [ABRecord] = []
    var matchingRecordsByName: [RecordName: (ABRecord, ABRecord)] = [:]

    for newRecord in newRecords {
      if let newRecordName = RecordName(ofRecord: newRecord) {
        let existingRecordsWithName = oldRecords.filter { oldRecord in
          if let oldRecordName = RecordName(ofRecord: oldRecord) {
            return oldRecordName == newRecordName
          } else {
            return false
          }
        }

        switch existingRecordsWithName.count {
        case 0:
          additions.append(newRecord)
        case 1:
          let existingRecord: ABRecord = existingRecordsWithName.first!
          matchingRecordsByName[newRecordName] = (existingRecord, newRecord)
        default:
          NSLog("Skipping update for multiple records having same name: %@", newRecordName.description)
        }
      }
    }

    return (additions, matchingRecordsByName)
  }

  private static func findChanges(
    matchingRecords: [RecordName: (ABRecord, ABRecord)])
    -> [RecordChangeSet]
  {
    var changeSets: [RecordChangeSet] = []

    for (_, (existingRecord, newRecord)) in matchingRecords {
      let changeSet = RecordChangeSet(oldRecord: existingRecord, newRecord: newRecord)
      if let cs = changeSet {
        changeSets.append(cs)
      }
    }

    return changeSets
  }
}
