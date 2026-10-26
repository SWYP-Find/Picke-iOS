public enum ClassResultAPI {
  case result(classID: Int)
  case myReport(classID: Int)
  case insight(classID: Int)
  case retryInsight(classID: Int)

  public var description: String {
    switch self {
    case let .result(id): return "classes/\(id)/result"
    case let .myReport(id): return "classes/\(id)/result/my-report"
    case let .insight(id): return "classes/\(id)/result/insight"
    case let .retryInsight(id): return "classes/\(id)/result/insight/retry"
    }
  }
}
