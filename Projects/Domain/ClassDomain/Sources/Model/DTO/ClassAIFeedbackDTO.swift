import ClassDomainInterface

struct ClassPersonalReportDTO: Decodable, Sendable {
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

      func toDomain() -> ClassAIFeedbackEvidence {
        ClassAIFeedbackEvidence(
          sourceType: sourceType,
          sourceID: sourceId,
          content: content,
          quote: quote,
          field: field
        )
      }
    }

    let headline: String
    let judgmentBasis: String
    let strength: Point?
    let nextFocus: Point?
    let nextQuestion: String
    let evidence: [Evidence]?
    let coverage: String?
    let excludedCount: Int?

    func toDomain() -> ClassAIPersonalFeedback {
      let points = [strength, nextFocus].compactMap(\.self).map {
        ClassAIFeedbackPoint(title: $0.title, detail: $0.body)
      }
      return ClassAIPersonalFeedback(
        summaryTitle: headline,
        summaryDetail: judgmentBasis,
        points: points,
        nextQuestion: nextQuestion,
        nextHint: "",
        evidence: evidence?.map { $0.toDomain() } ?? [],
        coverage: coverage,
        excludedCount: excludedCount ?? 0
      )
    }
  }

  let state: String
  let feedback: Feedback?

  func toDomain() throws -> ClassAIPersonalFeedback {
    switch state {
    case "SUCCEEDED", "LIMITED":
      guard let feedback else { throw ClassAIFeedbackError.generationFailed }
      return feedback.toDomain()
    case "BEFORE_CLOSE", "PENDING", "GENERATING":
      throw ClassAIFeedbackError.modelNotReady
    case "NOT_ELIGIBLE":
      throw ClassAIFeedbackError.insufficientInput
    case "FAILED":
      throw ClassAIFeedbackError.generationFailed
    default:
      throw ClassAIFeedbackError.generationFailed
    }
  }
}

struct ClassInsightDTO: Decodable, Sendable {
  struct Evidence: Decodable, Sendable {
    let sourceType: String?
    let id: Int?
    let sourceId: Int?
    let content: String
    let quote: String?

    func toDomain() -> ClassAIFeedbackEvidence {
      ClassAIFeedbackEvidence(
        sourceType: sourceType,
        sourceID: id ?? sourceId,
        content: content,
        quote: quote
      )
    }
  }

  let state: String
  let retryable: Bool
  let insightText: String?
  let evidence: [Evidence]?
  let highlights: [Evidence]?
  let coverage: String?
  let excludedCount: Int?

  func toDomain() throws -> ClassAIInsight {
    switch state {
    case "SUCCEEDED", "LIMITED":
      guard let insightText, !insightText.isEmpty else { throw ClassAIFeedbackError.generationFailed }
      return ClassAIInsight(
        text: insightText,
        evidence: evidence?.map { $0.toDomain() } ?? [],
        highlights: highlights?.map { $0.toDomain() } ?? [],
        coverage: coverage,
        excludedCount: excludedCount ?? 0
      )
    case "BEFORE_CLOSE", "PENDING", "GENERATING":
      throw ClassAIFeedbackError.modelNotReady
    case "FAILED":
      throw retryable ? ClassAIFeedbackError.serverRetryAvailable : .generationFailed
    default:
      throw ClassAIFeedbackError.generationFailed
    }
  }
}

struct ClassInsightRetryDTO: Decodable, Sendable {
  let state: String
}
