import Alamofire
import API
import Foundation
import PickeNetwork

enum ClassBattleService {
  case detail(classID: Int)
  case preVote(classID: Int, optionID: Int)
  case ttsComplete(classID: Int)
  case postVote(classID: Int, optionID: Int)
  case myVotes(classID: Int)
  case voteStats(classID: Int)
  case publishPerspective(classID: Int, content: String)
  case perspectives(classID: Int, cursor: String?, size: Int?, optionID: Int?, sort: String?)
  case myPerspectives(classID: Int)
}

extension ClassBattleService: PickeDataRequest {
  var domain: any PickeDomainType { ClassBattleDomain() }

  var path: String {
    switch self {
    case let .detail(classID): return "classes/\(classID)/battle"
    case let .preVote(classID, _): return "classes/\(classID)/battle/votes/pre"
    case let .ttsComplete(classID): return "classes/\(classID)/battle/votes/tts-complete"
    case let .postVote(classID, _): return "classes/\(classID)/battle/votes/post"
    case let .myVotes(classID): return "classes/\(classID)/battle/votes/me"
    case let .voteStats(classID): return "classes/\(classID)/battle/vote-stats"
    case let .publishPerspective(classID, _): return "classes/\(classID)/battle/perspectives"
    case let .perspectives(classID, _, _, _, _): return "classes/\(classID)/battle/perspectives"
    case let .myPerspectives(classID): return "classes/\(classID)/battle/perspectives/me"
    }
  }

  var method: HTTPMethod {
    switch self {
    case .detail, .myVotes, .voteStats, .perspectives, .myPerspectives: return .get
    case .preVote, .ttsComplete, .postVote, .publishPerspective: return .post
    }
  }

  var parameters: (any Encodable & Sendable)? {
    switch self {
    case let .preVote(_, optionID), let .postVote(_, optionID):
      return VoteBody(optionId: optionID)
    case let .publishPerspective(_, content):
      return PerspectiveBody(content: content)
    case let .perspectives(_, cursor, size, optionID, sort):
      return PerspectivesQuery(cursor: cursor, size: size, optionId: optionID, sort: sort)
    case .detail, .ttsComplete, .myVotes, .voteStats, .myPerspectives:
      return nil
    }
  }
}

private struct ClassBattleDomain: PickeDomainType {
  var baseURLString: String { PieckeDomain.battle.baseURLString }
  var url: String { "api/v1/" }
}

private struct VoteBody: Encodable, Sendable {
  let optionId: Int
}

private struct PerspectiveBody: Encodable, Sendable {
  let content: String
}

private struct PerspectivesQuery: Encodable, Sendable {
  let cursor: String?
  let size: Int?
  let optionId: Int?
  let sort: String?
}
