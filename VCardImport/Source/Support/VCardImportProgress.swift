private let MaxDownloadingToCompletionRatio: Float = 0.7
private let MaxCompletionToDownloadingRatio = 1 - MaxDownloadingToCompletionRatio

class VCardImportProgress {
  private var lastProgress: Float = 0
  private let numSources: Float
  private var downloadLeftBySourceId: [String: Float]

  init(sourceIds: [String]) {
    func makeDownloadDictionary() -> [String: Float] {
      var dict: [String: Float] = [:]
      for id in sourceIds {
        dict[id] = 1.0
      }
      return dict
    }

    numSources = Float(sourceIds.count)
    downloadLeftBySourceId = makeDownloadDictionary()
  }

  func step(type: Progress, forId id: String) -> Float {
    let progressStep = stepProgressLeft(type: type, id: id)
    let currentProgress = min(lastProgress + (1 / numSources) * progressStep, 1)
    lastProgress = currentProgress
    return currentProgress
  }

  private func stepProgressLeft(#type: Progress, id: String) -> Float {
    if let downloadLeft = downloadLeftBySourceId[id] {
      switch type {
      case .Completed:
        downloadLeftBySourceId.removeValueForKey(id)
        return downloadLeft * MaxDownloadingToCompletionRatio + MaxCompletionToDownloadingRatio
      case .Downloading(let completionStepRatio):
        let stepRatio = min(completionStepRatio, downloadLeft)
        downloadLeftBySourceId[id] = downloadLeft - stepRatio
        return stepRatio * MaxDownloadingToCompletionRatio
      }
    } else {
      return 0
    }
  }

  enum Progress {
    case Completed
    case Downloading(completionStepRatio: Float)

    func describeProgress(task: String) -> String {
      switch self {
      case Completed:
        return "Completed \(task)"
      case Downloading:
        return "Downloading \(task)…"
      }
    }
  }
}
