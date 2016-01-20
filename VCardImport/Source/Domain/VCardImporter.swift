import Foundation
import AddressBook
import MiniFuture

class VCardImporter {
  typealias OnSourceDownloadCallback = (VCardSource, HTTPRequest.ProgressBytes) -> Void
  typealias OnSourceCompleteCallback = (VCardSource, RecordDifferences?, ModifiedHeaderStamp?, ErrorType?) -> Void
  typealias OnCompleteCallback = ErrorType? -> Void

  private let onSourceDownload: OnSourceDownloadCallback
  private let onSourceComplete: OnSourceCompleteCallback
  private let onComplete: OnCompleteCallback
  private let urlDownloadFactory: URLDownloadFactory
  private let callbackQueue: QueueExecution.Queue

  private let executionQueue = QueueExecution.makeSerialQueue("VCardImporter")

  init(
    downloadsWith urlDownloadFactory: URLDownloadFactory,
    queueTo callbackQueue: QueueExecution.Queue,
    sourceDownloadHandler onSourceDownload: OnSourceDownloadCallback,
    sourceCompletionHandler onSourceComplete: OnSourceCompleteCallback,
    completionHandler onComplete: OnCompleteCallback)
  {
    self.onSourceDownload = onSourceDownload
    self.onSourceComplete = onSourceComplete
    self.onComplete = onComplete
    self.urlDownloadFactory = urlDownloadFactory
    self.callbackQueue = callbackQueue
  }

  func importFrom(sources: [VCardSource]) {
    // The implementation is long and ugly, but I prefer to keep dispatching
    // calls to background jobs and back to the user-specified queue in one
    // place.

    QueueExecution.async(executionQueue) {
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

        let recordDiff = RecordDifferences.resolveBetween(
          oldRecords: addressBook.loadRecords(),
          newRecords: loadedRecords)

        if !recordDiff.additions.isEmpty {
          do {
            try addressBook.addRecords(recordDiff.additions)
          } catch {
            QueueExecution.async(self.callbackQueue) {
              self.onSourceComplete(source, nil, nil, error)
            }
            continue
          }
        }

        if !recordDiff.changes.isEmpty {
          do {
            try self.changeRecords(recordDiff.changes)
          } catch {
            QueueExecution.async(self.callbackQueue) {
              self.onSourceComplete(source, nil, nil, error)
            }
            continue
          }
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

  private func changeRecords(changeSets: [RecordChangeSet]) throws {
    for changeSet in changeSets {
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
    }
  }

  private func checkAndDownloadSource(source: VCardSource) -> Future<SourceImportResult> {
    NSLog("vCard source %@: checking if vCard resource has changed, using %@ authentication method…",
      source.name,
      source.connection.authenticationMethod.rawValue)
    let downloader = urlDownloadFactory.makeDownloader(
      connection: source.connection,
      headers: Config.Net.VCardHTTPHeaders)
    return downloader
      .requestFileHeaders()
      .flatMap { [unowned self] response in
        let newStamp = ModifiedHeaderStamp(headers: response.allHeaderFields)

        if let oldStamp = source.lastImportResult?.modifiedHeaderStamp {
          if oldStamp == newStamp {
            NSLog("vCard source %@: vCard resource is unchanged since last import (\(oldStamp))", source.name)
            return Future.succeeded(.Unchanged)
          }
        }

        NSLog("vCard source %@: vCard resource has changed (\(newStamp)), downloading…", source.name)
        return self.downloadSource(source, downloadWith: downloader).map { records in .Changed(records, newStamp) }
    }
  }

  private func downloadSource(source: VCardSource, downloadWith urlDownloader: URLDownloadable) -> Future<[ABRecord]> {
    let fileURL = Files.tempURL()
    let onProgressCallback: HTTPRequest.OnProgressCallback = { progressBytes in
      QueueExecution.async(QueueExecution.mainQueue) { [unowned self] in
        self.onSourceDownload(source, progressBytes)
      }
    }
    let future = urlDownloader
      .downloadFile(to: fileURL, onProgress: onProgressCallback)
      .flatMap(loadRecordsFromFile)
    future.onComplete { _ in Files.remove(fileURL) }
    return future
  }

  private func loadRecordsFromFile(fileURL: NSURL) -> Future<[ABRecord]> {
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

  private enum SourceImportResult {
    case Unchanged
    case Changed([ABRecord], ModifiedHeaderStamp?)
  }
}
