public enum ClassDebateAPI {
  case debate(classID: Int)
  case replies(classID: Int)
  case retry(classID: Int)

  public var description: String {
    switch self {
    case let .debate(id): return "classes/\(id)/battle/debate"
    case let .replies(id): return "classes/\(id)/battle/debate/replies"
    case let .retry(id): return "classes/\(id)/battle/debate/retry"
    }
  }
}
