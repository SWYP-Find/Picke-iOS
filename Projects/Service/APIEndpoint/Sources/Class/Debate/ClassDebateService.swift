import Alamofire
import API
import Foundation
import PickeNetwork

public enum ClassDebateService {
  case fetch(Int)
  case start(Int)
  case submitReply(classID: Int, round: Int, content: String, requestKey: UUID)
  case retry(Int)
}

extension ClassDebateService: PickeDataRequest {
  public var domain: any PickeDomainType {
    PieckeDomain.classroom
  }

  public var path: String {
    switch self {
    case let .fetch(id), let .start(id): return ClassDebateAPI.debate(classID: id).description
    case let .submitReply(classID, _, _, _): return ClassDebateAPI.replies(classID: classID).description
    case let .retry(id): return ClassDebateAPI.retry(classID: id).description
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .fetch: return .get
    case .start, .submitReply, .retry: return .post
    }
  }

  public var parameters: (any Encodable & Sendable)? {
    switch self {
    case let .submitReply(_, round, content, requestKey):
      return ReplyBody(roundIndex: round, content: content, requestKey: requestKey.uuidString)
    case .fetch, .start, .retry:
      return nil
    }
  }
}
