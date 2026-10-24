//
//  ClassAIPersonalFeedback.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/12/26.
//

public struct ClassAIPersonalFeedback: Equatable, Sendable {
  public let summaryTitle: String
  public let summaryDetail: String
  public let points: [ClassAIFeedbackPoint]
  public let nextQuestion: String
  public let nextHint: String
  public let evidence: [ClassAIFeedbackEvidence]
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
    summaryTitle: String,
    summaryDetail: String,
    points: [ClassAIFeedbackPoint],
    nextQuestion: String,
    nextHint: String,
    evidence: [ClassAIFeedbackEvidence] = [],
    coverage: String? = nil,
    excludedCount: Int = 0
  ) {
    self.summaryTitle = summaryTitle
    self.summaryDetail = summaryDetail
    self.points = points
    self.nextQuestion = nextQuestion
    self.nextHint = nextHint
    self.evidence = evidence
    self.coverage = coverage
    self.excludedCount = excludedCount
  }
}
