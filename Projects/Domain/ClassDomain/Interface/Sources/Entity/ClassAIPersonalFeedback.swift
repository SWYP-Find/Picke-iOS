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

  public init(
    summaryTitle: String,
    summaryDetail: String,
    points: [ClassAIFeedbackPoint],
    nextQuestion: String,
    nextHint: String
  ) {
    self.summaryTitle = summaryTitle
    self.summaryDetail = summaryDetail
    self.points = points
    self.nextQuestion = nextQuestion
    self.nextHint = nextHint
  }
}
