import Alamofire
import API
import ClassDomainInterface
import Foundation
import PickeNetwork

enum ClassTopicDraftService {
  case create(ClassTopicFilter)
  case detail(Int)
  case suggest(Int, ClassTopicFilter?)
  case select(draftID: Int, batchNo: Int, candidateID: Int)
  case validate(draftID: Int, baseVersionID: Int, candidate: ClassTopicCandidate)
}

extension ClassTopicDraftService: PickeDataRequest {
  var domain: any PickeDomainType { ClassTopicDraftDomain() }

  var path: String {
    switch self {
    case .create: return "class-topic-drafts"
    case let .detail(id): return "class-topic-drafts/\(id)"
    case let .suggest(id, _): return "class-topic-drafts/\(id)/suggestions"
    case let .select(draftID, _, _): return "class-topic-drafts/\(draftID)/selection"
    case let .validate(draftID, _, _): return "class-topic-drafts/\(draftID)/validations"
    }
  }

  var method: HTTPMethod {
    switch self {
    case .detail: return .get
    case .create, .suggest, .select, .validate: return .post
    }
  }

  var parameters: (any Encodable & Sendable)? {
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

private struct ClassTopicDraftDomain: PickeDomainType {
  var baseURLString: String { PieckeDomain.battle.baseURLString }
  var url: String { "api/v1/" }
}

private struct TopicFilterBody: Encodable, Sendable {
  let topicSeed: String
  let difficulty: String
  let categories: [String]

  init(filter: ClassTopicFilter) {
    topicSeed = filter.keyword.trimmingCharacters(in: .whitespacesAndNewlines)
    difficulty = filter.level.topicAPIValue
    categories = filter.categories.reduce(into: [String]()) { titles, category in
      if !titles.contains(category.title) { titles.append(category.title) }
    }
  }
}

private struct TopicSelectionBody: Encodable, Sendable {
  let batchNo: Int
  let candidateId: Int
}

private struct TopicValidationBody: Encodable, Sendable {
  struct Option: Encodable, Sendable {
    let label: String
    let rationale: String
    let philosopher: String?
  }

  let baseVersionId: Int
  let question: String
  let description: String
  let options: [Option]

  init(baseVersionId: Int, candidate: ClassTopicCandidate) {
    self.baseVersionId = baseVersionId
    question = candidate.question
    description = candidate.description
    options = candidate.options.map {
      Option(label: $0.label, rationale: $0.rationale, philosopher: $0.philosopher)
    }
  }
}

private extension ClassAudienceLevel {
  var topicAPIValue: String {
    switch self {
    case .middle: return "BEGINNER"
    case .high: return "INTERMEDIATE"
    case .adult: return "ADVANCED"
    }
  }
}
