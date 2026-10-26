public struct ClassAIInsight: Equatable, Sendable {
  public let text: String
  public let evidence: [ClassAIFeedbackEvidence]
  public let highlights: [ClassAIFeedbackEvidence]
  public let coverage: String?
  public let excludedCount: Int

  public var coverageDescription: String? {
    switch coverage {
    case "full": return "전체 글을 분석했어요"
    case "partial": return "글 \(excludedCount)건을 제외하고 분석했어요"
    default: return nil
    }
  }

  public init(
    text: String,
    evidence: [ClassAIFeedbackEvidence] = [],
    highlights: [ClassAIFeedbackEvidence] = [],
    coverage: String? = nil,
    excludedCount: Int = 0
  ) {
    self.text = text
    self.evidence = evidence
    self.highlights = highlights
    self.coverage = coverage
    self.excludedCount = excludedCount
  }
}
