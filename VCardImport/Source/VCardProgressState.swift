class VCardProgressState {
  /// 70 % of progress per source is for downloading, left is for completion
  private let MaxDownloadingRatioToCompleted: Float = 0.7

  private var lastProgress: Float = 0
  private let numSources: Float
  private var progressLeftBySourceId: [String: Float]

  private weak var toolbar: VCardToolbar?

  init(toolbar: VCardToolbar, sources: [VCardSource]) {
    func makeProgressLeftDictionary() -> [String: Float] {
      var dict: [String: Float] = [:]
      for source in sources {
        dict[source.id] = 1.0
      }
      return dict
    }

    numSources = Float(sources.count)
    progressLeftBySourceId = makeProgressLeftDictionary()

    self.toolbar = toolbar
  }

  func inProgress(type: ProgressType, forSource source: VCardSource) {
    if let bar = toolbar {
      let progressStep = stepProgressLeft(type: type, id: source.id)
      let currentProgress = min(lastProgress + (1 / numSources) * progressStep, 1)
      let currentProgressText = type.describeProgress(source.name)

      NSLog("Progress: %0.2f/%0.2f (%@)", progressStep, currentProgress, currentProgressText)

      bar.inProgress(text: currentProgressText, progress: currentProgress)

      lastProgress = currentProgress
    }
  }

  private func stepProgressLeft(#type: ProgressType, id: String) -> Float {
    if let progressLeft = progressLeftBySourceId[id] {
      switch type {
      case .Completed:
        progressLeftBySourceId.removeValueForKey(id)
        return progressLeft
      case .Downloading(let bytes, let totalBytes, let totalBytesExpected):
        let step = Float(bytes) / Float(totalBytesExpected) * MaxDownloadingRatioToCompleted
        progressLeftBySourceId[id] = progressLeft - step
        return step
      }
    } else {
      return 0
    }
  }

  enum ProgressType {
    case Completed
    case Downloading(bytes: Int64, totalBytes: Int64, totalBytesExpected: Int64)

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
