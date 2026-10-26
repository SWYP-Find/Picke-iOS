import ClassDomainInterface

struct ClassPersonalReportDTO: Decodable, Sendable {
  struct VoteOption: Decodable, Sendable {
    let optionId: Int
    let title: String
    let stance: String?

  }

  struct Point: Decodable, Sendable {
    let title: String
    let body: String
  }

  struct Feedback: Decodable, Sendable {
    struct Evidence: Decodable, Sendable {
      let field: String?
      let sourceType: String
      let sourceId: Int
      let quote: String?
      let content: String

    }

    let headline: String
    let judgmentBasis: String
    let strength: Point?
    let nextFocus: Point?
    let nextQuestion: String
    let evidence: [Evidence]?
    let coverage: String?
    let excludedCount: Int?

  }

  let state: ClassAIGenerationState
  let feedback: Feedback?
  let preOption: VoteOption?
  let postOption: VoteOption?
  let perspectiveCount: Int?
  let commentCount: Int?
}

struct ClassInsightDTO: Decodable, Sendable {
  struct Evidence: Decodable, Sendable {
    let sourceType: String?
    let id: Int?
    let sourceId: Int?
    let content: String
    let quote: String?

  }

  let state: ClassAIGenerationState
  let retryable: Bool
  let insightText: String?
  let evidence: [Evidence]?
  let highlights: [Evidence]?
  let coverage: String?
  let excludedCount: Int?
}

struct ClassInsightRetryDTO: Decodable, Sendable {
  let state: ClassAIGenerationState
}
