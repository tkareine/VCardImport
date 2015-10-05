import Foundation
import AddressBook
import MiniFuture

class VCardImporter {
  typealias OnSourceDownloadCallback = (VCardSource, Request.ProgressBytes) -> Void
  typealias OnSourceCompleteCallback = (VCardSource, RecordDifferences?, ModifiedHeaderStamp?, ErrorType?) -> Void
  typealias OnCompleteCallback = ErrorType? -> Void

  private let onSourceDownload: OnSourceDownloadCallback
  private let onSourceComplete: OnSourceCompleteCallback
  private let onComplete: OnCompleteCallback
  private let urlConnection: URLConnectable
  private let callbackQueue: QueueExecution.Queue

  private let executionQueue = QueueExecution.makeSerialQueue("VCardImporter")

  class func builder() -> Builder {
    return Builder()
  }

  private init(
    onSourceDownload: OnSourceDownloadCallback,
    onSourceComplete: OnSourceCompleteCallback,
    onComplete: OnCompleteCallback,
    urlConnection: URLConnectable,
    callbackQueue: QueueExecution.Queue)
  {
    self.onSourceDownload = onSourceDownload
    self.onSourceComplete = onSourceComplete
    self.onComplete = onComplete
    self.urlConnection = urlConnection
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
        QueueExecution.async(self.callbackQueue) { self.onComplete(error) }
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
            self.onSourceComplete(source, nil, nil, Errors.addressBookFailedToLoadVCardSource((error as NSError).localizedDescription))
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
            QueueExecution.async(self.callbackQueue) { self.onSourceComplete(source, nil, nil, error) }
            continue
          }
        }

        if !recordDiff.changes.isEmpty {
          do {
            try self.changeRecords(recordDiff.changes)
          } catch {
            QueueExecution.async(self.callbackQueue) { self.onSourceComplete(source, nil, nil, error) }
            continue
          }
        }

        if addressBook.hasUnsavedChanges {
          do {
            try addressBook.save()
          } catch {
            QueueExecution.async(self.callbackQueue) { self.onSourceComplete(source, nil, nil, error) }
            continue
          }
        }

        NSLog("vCard source %@: %@", source.name, recordDiff.description)
        QueueExecution.async(self.callbackQueue) {
          self.onSourceComplete(source, recordDiff, modifiedHeaderStamp, nil)
        }
      }

      QueueExecution.async(self.callbackQueue) { self.onComplete(nil) }
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
    NSLog("vCard source %@: checking if remote has changed…", source.name)
    return urlConnection
      .head(
        source.connection.toURL(),
        headers: Config.Net.VCardHTTPHeaders,
        credential: source.connection.toCredential(.ForSession))
      .flatMap { response in
        let newStamp = ModifiedHeaderStamp(headers: response.allHeaderFields)

        if let oldStamp = source.lastImportResult?.modifiedHeaderStamp {
          if oldStamp == newStamp {
            NSLog("vCard source %@: remote is unchanged since last import (\(oldStamp))", source.name)
            return Future.succeeded(.Unchanged)
          }
        }

        NSLog("vCard source %@: remote has changed (\(newStamp)), downloading…", source.name)
        return self.downloadSource(source).map { records in .Changed(records, newStamp) }
      }
  }

  private func downloadSource(source: VCardSource) -> Future<[ABRecord]> {
    let fileURL = Files.tempURL()
    let onProgressCallback: Request.OnProgressCallback = { progressBytes in
      QueueExecution.async(QueueExecution.mainQueue) {
        self.onSourceDownload(source, progressBytes)
      }
    }
    let future = urlConnection
      .download(
        source.connection.toURL(),
        to: fileURL,
        headers: Config.Net.VCardHTTPHeaders,
        credential: source.connection.toCredential(.ForSession),
        onProgress: onProgressCallback)
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

  class Builder {
    private var onSourceDownload: OnSourceDownloadCallback?
    private var onSourceComplete: OnSourceCompleteCallback?
    private var onComplete: OnCompleteCallback?
    private var urlConnection: URLConnectable?
    private var callbackQueue: QueueExecution.Queue?

    func onSourceDownload(callback: OnSourceDownloadCallback) -> Builder {
      self.onSourceDownload = callback
      return self
    }

    func onSourceComplete(callback: OnSourceCompleteCallback) -> Builder {
      self.onSourceComplete = callback
      return self
    }

    func onComplete(callback: OnCompleteCallback) -> Builder {
      self.onComplete = callback
      return self
    }

    func connectWith(urlConnection: URLConnectable) -> Builder {
      self.urlConnection = urlConnection
      return self
    }

    func queueTo(callbackQueue: QueueExecution.Queue) -> Builder {
      self.callbackQueue = callbackQueue
      return self
    }

    func build() -> VCardImporter {
      return VCardImporter(
        onSourceDownload: self.onSourceDownload!,
        onSourceComplete: self.onSourceComplete!,
        onComplete: self.onComplete!,
        urlConnection: self.urlConnection!,
        callbackQueue: self.callbackQueue!)
    }
  }
}
