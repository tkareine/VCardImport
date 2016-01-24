private let DownloadProgressRatio: Float = 0.7
private let ResolveRecordsProgressRatio: Float = 0.1
private let ApplyRecordsProgressRatio: Float = 0.1

private func fixRatio(ratio: Float) -> Float {
  return min(1, max(0, ratio))
}

private func addToProgressDone(
  completionRatio completionRatio: Float,
  previousProgressDone: Float,
  minProgressDone: Float,
  progressRatio: Float)
  -> Float?
{
  let currentCompletionRatio = fixRatio(completionRatio)
  // Ignore previous types of events when we've already moved to processing
  // the current type of events. For example, when we first encounter an
  // `ApplyRecords` event, we begin ignoring `Download` and `ResolveRecords`
  // events.
  if previousProgressDone < minProgressDone + progressRatio {
    let correctedProgressDone = max(minProgressDone, previousProgressDone)
    let previousCompletionRatio = (correctedProgressDone - minProgressDone) / progressRatio
    if currentCompletionRatio >= previousCompletionRatio {
      let progressStep = (currentCompletionRatio - previousCompletionRatio) * progressRatio
      return correctedProgressDone + progressStep
    }
  }
  return nil
}

private func advanceProgressDone(
  progress: ImportProgress.Progress,
  previousProgressDone: Float)
  -> Float?
{
  switch progress {
  case .Download(let completionRatio):
    return addToProgressDone(
      completionRatio: completionRatio,
      previousProgressDone: previousProgressDone,
      minProgressDone: 0,
      progressRatio: DownloadProgressRatio)
  case .ResolveRecords(let completionRatio):
    return addToProgressDone(
      completionRatio: completionRatio,
      previousProgressDone: previousProgressDone,
      minProgressDone: DownloadProgressRatio,
      progressRatio: ResolveRecordsProgressRatio)
  case .ApplyRecords(let completionRatio):
    return addToProgressDone(
      completionRatio: completionRatio,
      previousProgressDone: previousProgressDone,
      minProgressDone: DownloadProgressRatio + ResolveRecordsProgressRatio,
      progressRatio: ApplyRecordsProgressRatio)
  case .Complete:
    return 1
  }
}

class ImportProgress {
  private var lastOverallProgress: Float = 0
  private var progressDoneBySourceId: [String: Float]

  init(sourceIds: [String]) {
    func makeProgressDictionary() -> [String: Float] {
      var dict: [String: Float] = [:]
      for id in sourceIds {
        dict[id] = 0
      }
      return dict
    }

    progressDoneBySourceId = makeProgressDictionary()
  }

  func inProgress(progress: Progress, forId id: String) -> Float {
    if let
      previousProgressDone = progressDoneBySourceId[id],
      currentProgressDone = advanceProgressDone(progress, previousProgressDone: previousProgressDone)
    {
      progressDoneBySourceId[id] = currentProgressDone
    }

    let overallDone = progressDoneBySourceId.reduce(0) { acc, sourceDone in
      acc + sourceDone.1
    }

    let numSources = Float(progressDoneBySourceId.count)

    return overallDone / numSources
  }

  enum Progress {
    case Download(completionRatio: Float)
    case ResolveRecords(completionRatio: Float)
    case ApplyRecords(completionRatio: Float)
    case Complete

    func describeProgress(task: String) -> String {
      switch self {
      case .Download:
        // don't show name as downloads happen in parallel
        return "Downloading…"
      case .ResolveRecords:
        return "Resolving \(task)…"
      case .ApplyRecords:
        return "Applying \(task)…"
      case .Complete:
        return "Completed \(task)"
      }
    }
  }
}
