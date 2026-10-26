import Alamofire
import API
import ClassDomainInterface
import Foundation
import PickeNetwork

public enum ClassTopicDraftService {
  case create(ClassTopicFilter)
  case detail(Int)
  case suggest(Int, ClassTopicFilter?)
  case select(draftID: Int, batchNo: Int, candidateID: Int)
  case validate(draftID: Int, baseVersionID: Int, candidate: ClassTopicCandidate)
}

extension ClassTopicDraftService: PickeDataRequest {
  public var domain: any PickeDomainType { PieckeDomain.classroom }

  public var path: String {
    switch self {
    case .create: return ClassTopicDraftAPI.drafts.description
    case let .detail(id): return ClassTopicDraftAPI.detail(draftID: id).description
    case let .suggest(id, _): return ClassTopicDraftAPI.suggestions(draftID: id).description
    case let .select(draftID, _, _): return ClassTopicDraftAPI.selection(draftID: draftID).description
    case let .validate(draftID, _, _): return ClassTopicDraftAPI.validations(draftID: draftID).description
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .detail: return .get
    case .create, .suggest, .select, .validate: return .post
    }
  }

  public var parameters: (any Encodable & Sendable)? {
    switch self {
    case let .create(filter):
      return TopicFilterBody(filter: filter)
    case .detail:
      return nil
    case let .suggest(_, filter):
      return filter.map(TopicFilterBody.init)
    case let .select(_, batchNo, candidateID):
      return TopicSelectionBody(batchNo: batchNo, candidateId: candidateID)
    case let .validate(_, baseVersionID, candidate):
      return TopicValidationBody(baseVersionId: baseVersionID, candidate: candidate)
    }
  }
}
