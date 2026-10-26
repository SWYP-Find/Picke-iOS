import ClassDomainInterface

extension ClassPersonalReportDTO.VoteOption {
  func toDomain() -> ClassAIFeedbackVoteChoice {
    ClassAIFeedbackVoteChoice(id: optionId, title: title, stance: stance)
  }
}

extension ClassPersonalReportDTO.Feedback.Evidence {
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

extension ClassPersonalReportDTO.Feedback {
  func toDomain(
    preOption: ClassPersonalReportDTO.VoteOption?,
    postOption: ClassPersonalReportDTO.VoteOption?,
    perspectiveCount: Int,
    commentCount: Int
  ) -> ClassAIPersonalFeedback {
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
      excludedCount: excludedCount ?? 0,
      preOption: preOption?.toDomain(),
      postOption: postOption?.toDomain(),
      perspectiveCount: perspectiveCount,
      commentCount: commentCount
    )
  }
}

extension ClassPersonalReportDTO {
  func toDomain() throws -> ClassAIPersonalFeedback {
    switch state {
    case .succeeded, .limited:
      guard let feedback else { throw ClassAIFeedbackError.generationFailed }
      return feedback.toDomain(
        preOption: preOption,
        postOption: postOption,
        perspectiveCount: perspectiveCount ?? 0,
        commentCount: commentCount ?? 0
      )
    case .beforeClose, .pending, .generating:
      throw ClassAIFeedbackError.modelNotReady
    case .notEligible:
      throw ClassAIFeedbackError.insufficientInput
    case .failed:
      throw ClassAIFeedbackError.generationFailed
    case .unknown:
      throw ClassAIFeedbackError.generationFailed
    }
  }
}

extension ClassInsightDTO.Evidence {
  func toDomain() -> ClassAIFeedbackEvidence {
    ClassAIFeedbackEvidence(
      sourceType: sourceType,
      sourceID: id ?? sourceId,
      content: content,
      quote: quote
    )
  }
}

extension ClassInsightDTO {
  func toDomain() throws -> ClassAIInsight {
    switch state {
    case .succeeded, .limited:
      guard let insightText, !insightText.isEmpty else { throw ClassAIFeedbackError.generationFailed }
      return ClassAIInsight(
        text: insightText,
        evidence: evidence?.map { $0.toDomain() } ?? [],
        highlights: highlights?.map { $0.toDomain() } ?? [],
        coverage: coverage,
        excludedCount: excludedCount ?? 0
      )
    case .beforeClose, .pending, .generating:
      throw ClassAIFeedbackError.modelNotReady
    case .failed:
      throw retryable ? ClassAIFeedbackError.serverRetryAvailable : .generationFailed
    case .notEligible, .unknown:
      throw ClassAIFeedbackError.generationFailed
    }
  }
}
