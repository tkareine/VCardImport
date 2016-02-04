import Foundation
import AddressBook

struct RecordDifferences {
  typealias ResolveProgress = (totalPhasesCompleted: Int, totalPhasesToComplete: Int)
  typealias OnResolveProgressCallback = ResolveProgress -> Void

  let additions: [ABRecord]
  let changes: [RecordChangeSet]
  let countSkippedNewRecordsWithDuplicateNames: Int
  let countSkippedAmbiguousMatchesToExistingRecords: Int

  static func resolveBetween(
    oldRecords oldRecords: [ABRecord],
    newRecords: [ABRecord],
    includePersonNicknameForEquality: Bool,
    onProgress: OnResolveProgressCallback? = nil)
    -> RecordDifferences
  {
    let (uniqueNewRecords, duplicateNewRecords) = uniqueRecordsOf(
      newRecords,
      includePersonNicknameForEquality: includePersonNicknameForEquality)
    let countDuplicateNewRecords = duplicateNewRecords.reduce(0) { $0 + $1.1 }

    onProgress?((totalPhasesCompleted: 1, totalPhasesToComplete: 4))

    let (uniqueOldRecords, duplicateOldRecords) = uniqueRecordsOf(
      oldRecords,
      includePersonNicknameForEquality: includePersonNicknameForEquality)

    onProgress?((totalPhasesCompleted: 2, totalPhasesToComplete: 4))

    let (additions, matches, countAmbiguousMatchesToOldRecords) =
      findAdditionsAndUpdatesBetween(
        oldRecords: uniqueOldRecords,
        newRecords: uniqueNewRecords,
        duplicateOldRecords: duplicateOldRecords)

    onProgress?((totalPhasesCompleted: 3, totalPhasesToComplete: 4))

    let changes = findChanges(matches, trackPersonNickname: !includePersonNicknameForEquality)

    onProgress?((totalPhasesCompleted: 4, totalPhasesToComplete: 4))

    return self.init(
      additions: additions,
      changes: changes,
      countSkippedNewRecordsWithDuplicateNames: countDuplicateNewRecords,
      countSkippedAmbiguousMatchesToExistingRecords: countAmbiguousMatchesToOldRecords)
  }

  private static func uniqueRecordsOf(
    records: [ABRecord],
    includePersonNicknameForEquality includePersonNickname: Bool)
    -> ([RecordName: ABRecord], [RecordName: Int])
  {
    var uniqueRecords: [RecordName: ABRecord] = [:]
    var duplicateRecords: [RecordName: Int] = [:]

    for rec in records {
      if let name = RecordName.of(rec, includePersonNickname: includePersonNickname) {
        if let countDuplicates = duplicateRecords[name] {
          duplicateRecords[name] = countDuplicates + 1
        } else {
          if uniqueRecords.hasKey(name) {
            uniqueRecords.removeValueForKey(name)
            duplicateRecords[name] = 2
          } else {
            uniqueRecords[name] = rec
          }
        }
      }
    }

    return (uniqueRecords, duplicateRecords)
  }

  private static func findAdditionsAndUpdatesBetween(
    oldRecords oldRecords: [RecordName: ABRecord],
    newRecords: [RecordName: ABRecord],
    duplicateOldRecords: [RecordName: Int])
    -> ([ABRecord], [RecordName: (ABRecord, ABRecord)], Int)
  {
    var additionsFound: [ABRecord] = []
    var updatesFound: [RecordName: (ABRecord, ABRecord)] = [:]
    var countAmbigiousMatchesToOldRecords = 0

    for (newRecordName, newRecord) in newRecords {
      if let oldRecord = oldRecords[newRecordName] {
        NSLog("Marking record for checking changes: %@", newRecordName.description)
        updatesFound[newRecordName] = (oldRecord, newRecord)
      } else if let countDuplicates = duplicateOldRecords[newRecordName] {
        NSLog("Ambigious match to old records: %d matches for %@", countDuplicates, newRecordName.description)
        countAmbigiousMatchesToOldRecords += countDuplicates
      } else {
        NSLog("Marking record for addition: %@", newRecordName.description)
        additionsFound.append(newRecord)
      }
    }

    return (additionsFound, updatesFound, countAmbigiousMatchesToOldRecords)
  }

  private static func findChanges(
    matchingRecords: [RecordName: (ABRecord, ABRecord)],
    trackPersonNickname: Bool)
    -> [RecordChangeSet]
  {
    var changeSets: [RecordChangeSet] = []

    for (recordName, (existingRecord, newRecord)) in matchingRecords {
      if let cs = RecordChangeSet(
        oldRecord: existingRecord,
        newRecord: newRecord,
        trackPersonNickName: trackPersonNickname)
      {
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
      print(String(
          format: ", skipped %d %@ in vCard file due to duplicate names",
          countSkippedNewRecordsWithDuplicateNames,
          countSkippedNewRecordsWithDuplicateNames > 1 ? "contacts" : "contact"),
        terminator: "",
        toStream: &result)
    }

    if countSkippedAmbiguousMatchesToExistingRecords > 0 {
      print(String(
          format: ", skipped updates to %d %@ due to ambiguous name matches",
          countSkippedAmbiguousMatchesToExistingRecords,
          countSkippedAmbiguousMatchesToExistingRecords > 1 ? "contacts" : "contact"),
        terminator: "",
        toStream: &result)
    }

    return result
  }
}
