import Foundation
import AddressBook

struct RecordUpdates {
  let newRecords: [ABRecord]
  let changeSets: [RecordChangeSet]

  static func collectFor(
    existingRecords: [ABRecord],
    from candidateRecords: [ABRecord])
    -> RecordUpdates
  {
    let (newRecords, matchingRecords) = findNewAndMatchingRecordsFor(existingRecords, from: candidateRecords)
    let changeSets = makeRecordChangeSets(matchingRecords)
    return RecordUpdates(newRecords: newRecords, changeSets: changeSets)
  }

  private static func findNewAndMatchingRecordsFor(
    existingRecords: [ABRecord],
    from candidateRecords: [ABRecord])
    -> ([ABRecord], [String: (ABRecord, ABRecord)])
  {
    var newRecords: [ABRecord] = []
    var matchingRecordsByName: [String: (ABRecord, ABRecord)] = [:]

    for candidateRecord in candidateRecords {
      let nameOfCandidateRecord = self.recordNameOf(candidateRecord)
      let existingRecordsWithName = existingRecords.filter { self.recordNameOf($0) == nameOfCandidateRecord }

      switch existingRecordsWithName.count {
      case 0:
        newRecords.append(candidateRecord)
      case 1:
        let existingRecord: ABRecord = existingRecordsWithName.first!
        let name = recordNameOf(existingRecord)
        matchingRecordsByName[name] = (existingRecord, candidateRecord)
      default:
        let name = recordNameOf(candidateRecord)
        NSLog("Skipping updating contact that has multiple records with the same name: %@", name)
      }
    }

    return (newRecords, matchingRecordsByName)
  }

  private static func makeRecordChangeSets(
    matchingRecords: [String: (ABRecord, ABRecord)])
    -> [RecordChangeSet]
  {
    var changeSets: [RecordChangeSet] = []

    for (name, (existingRecord, newRecord)) in matchingRecords {
      let changeSet = RecordChangeSet.resolve(name, oldRecord: existingRecord, newRecord: newRecord)
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
