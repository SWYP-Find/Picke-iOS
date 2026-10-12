//
//  ClassAIFeedbackContext.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/12/26.
//

import Foundation

public struct ClassAIFeedbackContext: Equatable, Sendable {
  public let kind: ClassAIFeedbackKind
  public let roomID: Int
  public let battleID: Int
  public let question: String
  public let optionA: String
  public let optionB: String
  public let initialChoice: String?
  public let finalChoice: String?
  public let initialVoteLeading: Double?
  public let finalVoteLeading: Double?
  public let metrics: ClassParticipationMetrics?
  public let writtenEvidence: [String]
  public let sourceOpinionIDs: [Int]

  private init(
    kind: ClassAIFeedbackKind,
    room: ClassRoom,
    initialChoice: String?,
    finalChoice: String?,
    initialVoteLeading: Double?,
    finalVoteLeading: Double?,
    metrics: ClassParticipationMetrics?,
    writtenEvidence: [String],
    sourceOpinionIDs: [Int]
  ) throws {
    let evidence = writtenEvidence.map(Self.cleaned).filter { !$0.isEmpty }
    guard !evidence.isEmpty else { throw ClassAIFeedbackError.insufficientInput }
    self.kind = kind
    roomID = room.id
    battleID = room.battle.id
    question = Self.cleaned(room.battle.title)
    optionA = Self.cleaned(room.battle.optionATitle)
    optionB = Self.cleaned(room.battle.optionBTitle)
    self.initialChoice = initialChoice.map(Self.cleaned)
    self.finalChoice = finalChoice.map(Self.cleaned)
    self.initialVoteLeading = initialVoteLeading
    self.finalVoteLeading = finalVoteLeading
    self.metrics = metrics
    self.writtenEvidence = evidence
    self.sourceOpinionIDs = sourceOpinionIDs
  }

  public static func personal(
    room: ClassRoom,
    report: ClassReport,
    isOwner: Bool
  ) throws -> Self {
    let selected = report.myOpinions + [report[.commentBody], report[.replyBody]]
    return try Self(
      kind: isOwner ? .ownerPersonal : .studentPersonal,
      room: room,
      initialChoice: report[.initialChoice],
      finalChoice: report[.finalChoice],
      initialVoteLeading: report.initialVoteLeading,
      finalVoteLeading: report.finalVoteLeading,
      metrics: nil,
      writtenEvidence: Array(selected.filter { !Self.cleaned($0).isEmpty }.prefix(4)),
      sourceOpinionIDs: []
    ).limited(maxExcerpts: 4, maxExcerptLength: 240, maxDataCharacters: 2400)
  }

  public static func classInsight(
    room: ClassRoom,
    dashboard: ClassOwnerDashboardData
  ) throws -> Self {
    let selected = dashboard.opinions
      .filter { !$0.isReported && !Self.cleaned($0.text).isEmpty }
      .sorted { lhs, rhs in
        if lhs.recommendationCount != rhs.recommendationCount {
          switch (lhs.recommendationCount, rhs.recommendationCount) {
          case let (left?, right?): return left > right
          case (_?, nil): return true
          case (nil, _?): return false
          case (nil, nil): break
          }
        }
        if lhs.createdAt != rhs.createdAt {
          switch (lhs.createdAt, rhs.createdAt) {
          case let (left?, right?): return left > right
          case (_?, nil): return true
          case (nil, _?): return false
          case (nil, nil): break
          }
        }
        return lhs.id < rhs.id
      }
      .prefix(8)
    return try Self(
      kind: .classInsight,
      room: room,
      initialChoice: nil,
      finalChoice: nil,
      initialVoteLeading: nil,
      finalVoteLeading: nil,
      metrics: dashboard.metrics,
      writtenEvidence: selected.map(\.text),
      sourceOpinionIDs: selected.map(\.id)
    ).limited(maxExcerpts: 8, maxExcerptLength: 240, maxDataCharacters: 2400)
  }

  public func limited(
    maxExcerpts: Int,
    maxExcerptLength: Int,
    maxDataCharacters: Int
  ) throws -> Self {
    guard maxExcerpts > 0, maxExcerptLength > 0, maxDataCharacters > 0 else {
      throw ClassAIFeedbackError.insufficientInput
    }
    var remaining = maxDataCharacters
    func take(_ value: String, maximum: Int) -> String {
      let result = String(value.prefix(min(maximum, max(0, remaining))))
      remaining -= result.count
      return result
    }
    let question = take(question, maximum: maxDataCharacters / 3)
    let optionA = take(optionA, maximum: maxDataCharacters / 6)
    let optionB = take(optionB, maximum: maxDataCharacters / 6)
    let initialChoice = initialChoice.map { take($0, maximum: 120) }
    let finalChoice = finalChoice.map { take($0, maximum: 120) }
    var evidence: [String] = []
    var opinionIDs: [Int] = []
    for (index, item) in writtenEvidence.prefix(maxExcerpts).enumerated() where remaining > 0 {
      let excerpt = take(item, maximum: maxExcerptLength)
      if !Self.cleaned(excerpt).isEmpty {
        evidence.append(excerpt)
        if sourceOpinionIDs.indices.contains(index) {
          opinionIDs.append(sourceOpinionIDs[index])
        }
      }
    }
    guard !evidence.isEmpty else { throw ClassAIFeedbackError.insufficientInput }
    return Self(
      kind: kind,
      roomID: roomID,
      battleID: battleID,
      question: question,
      optionA: optionA,
      optionB: optionB,
      initialChoice: initialChoice,
      finalChoice: finalChoice,
      initialVoteLeading: initialVoteLeading,
      finalVoteLeading: finalVoteLeading,
      metrics: metrics,
      writtenEvidence: evidence,
      sourceOpinionIDs: opinionIDs
    )
  }

  public func shrunkAfterContextOverflow() throws -> Self {
    let remainingCount = writtenEvidence.count > 1 ? max(1, writtenEvidence.count / 2) : 1
    let excerptLength = writtenEvidence.count == 1 ? max(1, writtenEvidence[0].count / 2) : 240
    let dataLength = writtenEvidence.count == 1 ? 450 : 900
    let shrunk = try limited(
      maxExcerpts: remainingCount,
      maxExcerptLength: excerptLength,
      maxDataCharacters: dataLength
    )
    guard shrunk != self else { throw ClassAIFeedbackError.contextTooLong }
    return shrunk
  }

  private init(
    kind: ClassAIFeedbackKind,
    roomID: Int,
    battleID: Int,
    question: String,
    optionA: String,
    optionB: String,
    initialChoice: String?,
    finalChoice: String?,
    initialVoteLeading: Double?,
    finalVoteLeading: Double?,
    metrics: ClassParticipationMetrics?,
    writtenEvidence: [String],
    sourceOpinionIDs: [Int]
  ) {
    self.kind = kind
    self.roomID = roomID
    self.battleID = battleID
    self.question = question
    self.optionA = optionA
    self.optionB = optionB
    self.initialChoice = initialChoice
    self.finalChoice = finalChoice
    self.initialVoteLeading = initialVoteLeading
    self.finalVoteLeading = finalVoteLeading
    self.metrics = metrics
    self.writtenEvidence = writtenEvidence
    self.sourceOpinionIDs = sourceOpinionIDs
  }

  private static func cleaned(_ text: String) -> String {
    text.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
