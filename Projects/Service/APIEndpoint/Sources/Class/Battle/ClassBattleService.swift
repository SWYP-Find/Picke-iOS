import Alamofire
import API
import Foundation
import PickeNetwork

public enum ClassBattleService {
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
  public var domain: any PickeDomainType { PieckeDomain.classroom }

  public var path: String {
    switch self {
    case let .detail(classID): return ClassBattleAPI.detail(classID: classID).description
    case let .preVote(classID, _): return ClassBattleAPI.preVote(classID: classID).description
    case let .ttsComplete(classID): return ClassBattleAPI.ttsComplete(classID: classID).description
    case let .postVote(classID, _): return ClassBattleAPI.postVote(classID: classID).description
    case let .myVotes(classID): return ClassBattleAPI.myVotes(classID: classID).description
    case let .voteStats(classID): return ClassBattleAPI.voteStats(classID: classID).description
    case let .publishPerspective(classID, _), let .perspectives(classID, _, _, _, _):
      return ClassBattleAPI.perspectives(classID: classID).description
    case let .myPerspectives(classID): return ClassBattleAPI.myPerspectives(classID: classID).description
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .detail, .myVotes, .voteStats, .perspectives, .myPerspectives: return .get
    case .preVote, .ttsComplete, .postVote, .publishPerspective: return .post
    }
  }

  public var parameters: (any Encodable & Sendable)? {
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
