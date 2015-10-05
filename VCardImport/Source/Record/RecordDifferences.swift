import Foundation
import AddressBook

struct RecordDifferences {
  let additions: [ABRecord]
  let changes: [RecordChangeSet]
  let countSkippedNewRecordsWithDuplicateNames: Int
  let countSkippedAmbiguousMatchesToExistingRecords: Int

  static func resolveBetween(
    oldRecords oldRecords: [ABRecord],
    newRecords: [ABRecord])
    -> RecordDifferences
  {
    let (uniqueNewRecords, countSkippedNewRecordsWithDuplicateNames) = uniqueRecordsOf(newRecords)
    let (additions, matches, countSkippedAmbiguousMatchesToExistingRecords) = findAdditionsAndExistingMatchesBetween(oldRecords, uniqueNewRecords)
    let changes = findChanges(matches)
    return self.init(
      additions: additions,
      changes: changes,
      countSkippedNewRecordsWithDuplicateNames: countSkippedNewRecordsWithDuplicateNames,
      countSkippedAmbiguousMatchesToExistingRecords: countSkippedAmbiguousMatchesToExistingRecords)
  }

  private static func uniqueRecordsOf(records: [ABRecord])
    -> ([RecordName: ABRecord], Int)
  {
    var uniqueRecords: [RecordName: ABRecord] = [:]
    var skippedRecords: [RecordName: Int] = [:]

    for rec in records {
      if let name = RecordName.of(rec) {
        if let skips = skippedRecords[name] {
          skippedRecords[name] = skips + 1
        } else {
          if uniqueRecords.hasKey(name) {
            uniqueRecords.removeValueForKey(name)
            skippedRecords[name] = 2
          } else {
            uniqueRecords[name] = rec
          }
        }
      }
    }

    let totalSkipped = skippedRecords.reduce(0) { sum, kv in sum + kv.1 }

    return (uniqueRecords, totalSkipped)
  }

  private static func findAdditionsAndExistingMatchesBetween(
    oldRecords: [ABRecord],
    _ newRecords: [RecordName: ABRecord])
    -> ([ABRecord], [RecordName: (ABRecord, ABRecord)], Int)
  {
    var additions: [ABRecord] = []
    var matchingRecordsByName: [RecordName: (ABRecord, ABRecord)] = [:]
    var countSkipped = 0

    for (newRecordName, newRecord) in newRecords {
      let existingRecordsWithName = oldRecords.filter { oldRecord in
        if let oldRecordName = RecordName.of(oldRecord) {
          return oldRecordName == newRecordName
        } else {
          return false
        }
      }

      let countMatchingRecords = existingRecordsWithName.count

      switch countMatchingRecords {
      case 0:
        NSLog("Marking record for addition: %@", newRecordName.description)
        additions.append(newRecord)
      case 1:
        NSLog("Marking record for checking changes: %@", newRecordName.description)
        let existingRecord: ABRecord = existingRecordsWithName.first!
        matchingRecordsByName[newRecordName] = (existingRecord, newRecord)
      default:
        countSkipped += countMatchingRecords
        NSLog("Skipping update for multiple existing records having same name: %@", newRecordName.description)
      }
    }

    return (additions, matchingRecordsByName, countSkipped)
  }

  private static func findChanges(
    matchingRecords: [RecordName: (ABRecord, ABRecord)])
    -> [RecordChangeSet]
  {
    var changeSets: [RecordChangeSet] = []

    for (recordName, (existingRecord, newRecord)) in matchingRecords {
      if let cs = RecordChangeSet(oldRecord: existingRecord, newRecord: newRecord) {
        NSLog("Marking record for having changes: %@", recordName.description)
        changeSets.append(cs)
      }
    }

    return changeSets
  }
}

extension RecordDifferences: CustomStringConvertible {
  var description: String {
    func pluralizeUnit(singularUnit: String, pluralUnit: String, count: Int)
      -> String
    {
      return count > 1
        ? "\(count) \(pluralUnit)"
        : "\(count) \(singularUnit)"
    }

    let countAdditions = additions.count
    let countUpdates = changes.count

    var result = ""

    if countAdditions == 0 && countUpdates == 0 {
      print("Nothing to change", terminator: "", toStream: &result)
    } else {
      if countAdditions == 0 {
        print("No additions", terminator: "", toStream: &result)
      } else {
        print(pluralizeUnit("addition", pluralUnit: "additions", count: countAdditions), terminator: "", toStream: &result)
      }

      print(", ", terminator: "", toStream: &result)

      if countUpdates == 0 {
        print("no updates", terminator: "", toStream: &result)
      } else {
        print(pluralizeUnit("update", pluralUnit: "updates", count: countUpdates), terminator: "", toStream: &result)
      }
    }

    if countSkippedNewRecordsWithDuplicateNames > 0 {
      print(", skipped \(countSkippedNewRecordsWithDuplicateNames) contacts in vCard file due to duplicate names", terminator: "", toStream: &result)
    }

    if countSkippedAmbiguousMatchesToExistingRecords > 0 {
      print(", skipped updates to \(countSkippedAmbiguousMatchesToExistingRecords) contacts due to ambiguous name matches", terminator: "", toStream: &result)
    }

    return result
  }
}
