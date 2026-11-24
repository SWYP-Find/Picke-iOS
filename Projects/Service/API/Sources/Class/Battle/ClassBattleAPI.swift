public enum ClassBattleAPI {
  case detail(classID: Int)
  case preVote(classID: Int)
  case midVote(classID: Int)
  case ttsComplete(classID: Int)
  case postVote(classID: Int)
  case myVotes(classID: Int)
  case voteStats(classID: Int)
  case perspectives(classID: Int)
  case myPerspectives(classID: Int)

  public var description: String {
    switch self {
    case let .detail(id): return "classes/\(id)/battle"
    case let .preVote(id): return "classes/\(id)/battle/votes/pre"
    case let .midVote(id): return "classes/\(id)/battle/votes/mid"
    case let .ttsComplete(id): return "classes/\(id)/battle/votes/tts-complete"
    case let .postVote(id): return "classes/\(id)/battle/votes/post"
    case let .myVotes(id): return "classes/\(id)/battle/votes/me"
    case let .voteStats(id): return "classes/\(id)/battle/vote-stats"
    case let .perspectives(id): return "classes/\(id)/battle/perspectives"
    case let .myPerspectives(id): return "classes/\(id)/battle/perspectives/me"
    }
  }
}
