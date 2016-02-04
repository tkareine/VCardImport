import Foundation
import AddressBook
import MiniFuture

private let ExecutionQueue = QueueExecution.makeSerialQueue("VCardImportTask")

class VCardImportTask {
  typealias OnSourceCompleteCallback = (VCardSource, RecordDifferences?, ModifiedHeaderStamp?, ErrorType?) -> Void
  typealias OnCompleteCallback = ErrorType? -> Void
  typealias OnSourceDownloadCallback = (VCardSource, HTTPRequest.DownloadProgress) -> Void
  typealias OnSourceResolveRecordsCallback = (VCardSource, RecordDifferences.ResolveProgress) -> Void
  typealias OnSourceApplyRecordsCallback = (VCardSource, ApplyRecordsProgress) -> Void

  typealias ApplyRecordsProgress = (totalAdded: Int, totalChanged: Int, totalToApply: Int)

  private let urlDownloadFactory: URLDownloadFactory
  private let callbackQueue: QueueExecution.Queue
  private let onSourceComplete: OnSourceCompleteCallback
  private let onComplete: OnCompleteCallback
  private let onSourceDownloadProgress: OnSourceDownloadCallback?
  private let onSourceResolveRecordsProgress: OnSourceResolveRecordsCallback?
  private let onSourceApplyRecordsProgress: OnSourceApplyRecordsCallback?

  init(
    downloadsWith urlDownloadFactory: URLDownloadFactory,
    queueTo callbackQueue: QueueExecution.Queue,
    sourceCompletionHandler onSourceComplete: OnSourceCompleteCallback,
    completionHandler onComplete: OnCompleteCallback,
    onSourceDownloadProgress: OnSourceDownloadCallback? = nil,
    onSourceResolveRecordsProgress: OnSourceResolveRecordsCallback? = nil,
    onSourceApplyRecordsProgress: OnSourceApplyRecordsCallback? = nil)
  {
    self.urlDownloadFactory = urlDownloadFactory
    self.callbackQueue = callbackQueue
    self.onSourceComplete = onSourceComplete
    self.onComplete = onComplete
    self.onSourceDownloadProgress = onSourceDownloadProgress
    self.onSourceResolveRecordsProgress = onSourceResolveRecordsProgress
    self.onSourceApplyRecordsProgress = onSourceApplyRecordsProgress
  }

  func importFrom(sources: [VCardSource]) {
    // The implementation is long and ugly, but I prefer to keep dispatching
    // calls to background jobs and back to the user-specified queue in one
    // place.

    QueueExecution.async(ExecutionQueue) {
      let addressBook: AddressBook

      do {
        addressBook = try AddressBook.sharedInstance()
      } catch {
        QueueExecution.async(self.callbackQueue) {
          self.onComplete(error)
        }
        return
      }

      let sourceImports: [(VCardSource, Future<SourceImportResult>)] = sources.map { source in
        (source, self.checkAndDownloadSource(source))
      }

      for (source, sourceImport) in sourceImports {
        let importResult = sourceImport.get()

        let loadedRecords: [ABRecord]
        let modifiedHeaderStamp: ModifiedHeaderStamp?

        switch importResult {
        case .Success(let value):
          switch value {
          case .Unchanged:
            QueueExecution.async(self.callbackQueue) {
              self.onSourceComplete(source, nil, nil, nil)
            }
            continue
          case .Changed(let records, let stamp):
            loadedRecords = records
            modifiedHeaderStamp = stamp
          }
        case .Failure(let error):
          QueueExecution.async(self.callbackQueue) {
            self.onSourceComplete(source, nil, nil, error)
          }
          continue
        }

        let recordDiff = self.resolveRecordDifferences(
          oldRecords: addressBook.loadRecords(),
          newRecords: loadedRecords,
          forSource: source)

        do {
          try self.applyRecordDifferences(
            recordDiff,
            to: addressBook,
            forSource: source)
        } catch {
          QueueExecution.async(self.callbackQueue) {
            self.onSourceComplete(source, nil, nil, error)
          }
          continue
        }

        if addressBook.hasUnsavedChanges {
          do {
            try addressBook.save()
          } catch {
            QueueExecution.async(self.callbackQueue) {
              self.onSourceComplete(source, nil, nil, error)
            }
            continue
          }
        }

        NSLog("vCard source %@: %@", source.name, recordDiff.description)
        QueueExecution.async(self.callbackQueue) {
          self.onSourceComplete(source, recordDiff, modifiedHeaderStamp, nil)
        }
      }

      QueueExecution.async(self.callbackQueue) {
        self.onComplete(nil)
      }
    }
  }

  private func checkAndDownloadSource(source: VCardSource) -> Future<SourceImportResult> {
    let queue = callbackQueue
    let onDownloadProgress = onSourceDownloadProgress

    func downloadSource(urlDownloader: URLDownloadable) -> Future<[ABRecord]> {
      let fileURL = Files.tempURL()
      let onProgress: HTTPRequest.OnDownloadProgressCallback?

      if let callback = onDownloadProgress {
        onProgress = QueueExecution.makeThrottler(Config.UI.ImportProgressThrottleInMS) { progress in
          QueueExecution.async(queue) {
            callback(source, progress)
          }
        }
      } else {
        onProgress = nil
      }

      let future = urlDownloader
        .downloadFile(to: fileURL, onProgress: onProgress)
        .flatMap(loadRecordsFromFile)
      future.onComplete { _ in Files.remove(fileURL) }
      return future
    }

    func loadRecordsFromFile(fileURL: NSURL) -> Future<[ABRecord]> {
      let vcardData = NSData(contentsOfURL: fileURL)
      if let records = ABPersonCreatePeopleInSourceWithVCardRepresentation(nil, vcardData) {
        let foundRecords = records.takeRetainedValue() as [ABRecord]
        if foundRecords.isEmpty {
          return Future.failed(Errors.addressBookFailedToLoadVCardSource("no contact data found from vCard file"))
        } else {
          return Future.succeeded(foundRecords)
        }
      } else {
        return Future.failed(Errors.addressBookFailedToLoadVCardSource("invalid vCard file"))
      }
    }
    
    NSLog("vCard source %@: checking if vCard resource has changed, using %@ authentication method…",
      source.name,
      source.connection.authenticationMethod.rawValue)

    let downloader = urlDownloadFactory.makeDownloader(
      connection: source.connection,
      headers: Config.Net.VCardHTTPHeaders)

    return downloader
      .requestFileHeaders()
      .flatMap { response in
        let newStamp = ModifiedHeaderStamp(headers: response.allHeaderFields)

        if let oldStamp = source.lastImportResult?.modifiedHeaderStamp where oldStamp == newStamp {
          NSLog("vCard source %@: vCard resource is unchanged since last import (\(oldStamp))", source.name)
          return Future.succeeded(.Unchanged)
        }

        NSLog("vCard source %@: vCard resource has changed (\(newStamp)), downloading…", source.name)
        return downloadSource(downloader).map { records in .Changed(records, newStamp) }
    }
  }

  private func resolveRecordDifferences(
    oldRecords oldRecords: [ABRecord],
    newRecords: [ABRecord],
    forSource source: VCardSource)
    -> RecordDifferences
  {
    let queue = callbackQueue
    let onProgress: RecordDifferences.OnResolveProgressCallback?

    if let callback = onSourceResolveRecordsProgress {
      onProgress = QueueExecution.makeThrottler(Config.UI.ImportProgressThrottleInMS) { progress in
        QueueExecution.async(queue) {
          callback(source, progress)
        }
      }
    } else {
      onProgress = nil
    }

    return RecordDifferences.resolveBetween(
      oldRecords: oldRecords,
      newRecords: newRecords,
      includePersonNicknameForEquality: true,
      onProgress: onProgress)
  }
  
  private func applyRecordDifferences(
    recordDiff: RecordDifferences,
    to addressBook: AddressBook,
    forSource source: VCardSource)
    throws
  {
    let queue = callbackQueue
    let onProgress: (ApplyRecordsProgress -> Void)?

    if let callback = onSourceApplyRecordsProgress {
      onProgress = QueueExecution.makeThrottler(Config.UI.ImportProgressThrottleInMS) { progress in
        QueueExecution.async(queue) {
          callback(source, progress)
        }
      }
    } else {
      onProgress = nil
    }

    let totalToApply = recordDiff.additions.count + recordDiff.changes.count
    var totalAdded = 0
    var totalChanged = 0

    for record in recordDiff.additions {
      try addressBook.addRecord(record)
      totalAdded += 1
      onProgress?((totalAdded: totalAdded, totalChanged: totalChanged, totalToApply: totalToApply))
    }

    for changeSet in recordDiff.changes {
      for (property, value) in changeSet.singleValueChanges {
        let isChanged = Records.setValue(value, toSingleValueProperty: property, of: changeSet.record)
        if !isChanged {
          throw Errors.addressBookFailedToChange(property, of: changeSet.record)
        }
      }

      for (property, changes) in changeSet.multiValueChanges {
        let isChanged = Records.addValues(
          changes,
          toMultiValueProperty: property,
          of: changeSet.record)
        if !isChanged {
          throw Errors.addressBookFailedToChange(property, of: changeSet.record)
        }
      }

      if let img = changeSet.imageChange {
        let isChanged = Records.setImage(img, of: changeSet.record)
        if !isChanged {
          throw Errors.addressBookFailedToChangeImage(of: changeSet.record)
        }
      }

      totalChanged += 1
      onProgress?((totalAdded: totalAdded, totalChanged: totalChanged, totalToApply: totalToApply))
    }
  }

  private enum SourceImportResult {
    case Unchanged
    case Changed([ABRecord], ModifiedHeaderStamp?)
  }
}
