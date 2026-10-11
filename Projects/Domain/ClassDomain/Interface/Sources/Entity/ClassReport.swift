//
//  ClassReport.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/11/26.
//

public struct ClassReport: Equatable, Sendable {
  public enum Key: Hashable, Sendable {
    case aiSummaryTitle, aiSummaryDetail, teacherSummary
    case commentStance, commentDate, commentBody, commentLikes, commentReplies
    case replyAuthor, replyParent, replyBody, replyDate, replyLikes
    case participantTitle, participantCount, classSummary
    case bestAuthor, bestBody, bestLikes, bestReplies
    case feedbackTitle1, feedbackDetail1, feedbackTitle2, feedbackDetail2
    case feedbackTitle3, feedbackDetail3, nextQuestion, nextHint
    case teacherFeedback, teacherName, teacherDate
    case initialChoice, finalChoice, commentCount, replyCount, receivedLikeCount
  }

  public let texts: [Key: String]
  public let myOpinions: [String]
  public let initialVoteLeading: Double
  public let finalVoteLeading: Double
  public let layout: ClassReportLayout

  public init(
    texts: [Key: String],
    myOpinions: [String],
    initialVoteLeading: Double,
    finalVoteLeading: Double,
    layout: ClassReportLayout
  ) {
    self.texts = texts
    self.myOpinions = myOpinions
    self.initialVoteLeading = initialVoteLeading
    self.finalVoteLeading = finalVoteLeading
    self.layout = layout
  }

  public subscript(_ key: Key) -> String {
    texts[key] ?? ""
  }
}
