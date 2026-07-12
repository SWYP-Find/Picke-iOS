//
//  VoteQuestion.swift
//  Entity
//
//  Created by Wonji Suh on 5/15/26.
//

import Foundation

/// "오늘의 Pické — 투표" 카드 — API 의 todayVotes.
public struct VoteQuestion: Equatable, Identifiable {
  public let battleId: Int
  public let titlePrefix: String
  public let titleSuffix: String
  public let summary: String
  public let participantCount: Int
  public let options: [VoteOption]

  public var id: Int { battleId }

  public init(
    battleId: Int,
    titlePrefix: String,
    titleSuffix: String,
    summary: String,
    participantCount: Int,
    options: [VoteOption]
  ) {
    self.battleId = battleId
    self.titlePrefix = titlePrefix
    self.titleSuffix = titleSuffix
    self.summary = summary
    self.participantCount = participantCount
    self.options = options
  }

  // 기존 코드 호환용
  public var prefix: String { titlePrefix }
  public var suffix: String { titleSuffix }
}

public extension VoteQuestion {
  static let mock = VoteQuestion(
    battleId: 41,
    titlePrefix: "도덕의 기준은",
    titleSuffix: "이다",
    summary: "빈칸에 들어갈 가장 적절한 답을 골라주세요",
    participantCount: 985,
    options: [
      .init(label: "A", title: "결과"),
      .init(label: "B", title: "의도"),
      .init(label: "C", title: "규칙"),
      .init(label: "D", title: "덕"),
    ]
  )
}
