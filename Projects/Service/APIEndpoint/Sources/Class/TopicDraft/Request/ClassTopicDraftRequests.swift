import Foundation
import ClassDomainInterface

struct TopicFilterBody: Encodable, Sendable {
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

struct TopicSelectionBody: Encodable, Sendable {
  let batchNo: Int
  let candidateId: Int
}

struct TopicValidationBody: Encodable, Sendable {
  struct Option: Encodable, Sendable {
    let label: String
    let rationale: String
    let philosopher: String?
  }

  let baseVersionId: Int
  let question: String
  let description: String
  let options: [Option]

  init(
    baseVersionId: Int,
    candidate: ClassTopicCandidate
  ) {
    self.baseVersionId = baseVersionId
    question = candidate.question
    description = candidate.description
    options = candidate.options.map {
      Option(label: $0.label, rationale: $0.rationale, philosopher: $0.philosopher)
    }
  }
}

extension ClassAudienceLevel {
  var topicAPIValue: String {
    switch self {
    case .middle: return "BEGINNER"
    case .high: return "INTERMEDIATE"
    case .adult: return "ADVANCED"
    }
  }
}
