import Alamofire
import API
import Foundation
import PickeNetwork

enum ClassDebateService {
  case fetch(Int)
  case start(Int)
  case submitReply(classID: Int, round: Int, content: String, requestKey: UUID)
  case retry(Int)
}

extension ClassDebateService: PickeDataRequest {
  var domain: any PickeDomainType {
    ClassDebateDomain()
  }

  var path: String {
    switch self {
    case let .fetch(id), let .start(id): return "classes/\(id)/battle/debate"
    case let .submitReply(classID, _, _, _): return "classes/\(classID)/battle/debate/replies"
    case let .retry(id): return "classes/\(id)/battle/debate/retry"
    }
  }

  var method: HTTPMethod {
    switch self {
    case .fetch: return .get
    case .start, .submitReply, .retry: return .post
    }
  }

  var parameters: (any Encodable & Sendable)? {
    switch self {
    case let .submitReply(_, round, content, requestKey):
      return ReplyBody(roundIndex: round, content: content, requestKey: requestKey.uuidString)
    case .fetch, .start, .retry:
      return nil
    }
  }
}

private struct ClassDebateDomain: PickeDomainType {
  var baseURLString: String {
    PieckeDomain.battle.baseURLString
  }

  var url: String {
    "api/v1/"
  }
}

private struct ReplyBody: Encodable, Sendable {
  let roundIndex: Int
  let content: String
  let requestKey: String
}
