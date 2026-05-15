//
//  VoteQuestion.swift
//  Entity
//
//  Created by Wonji Suh on 5/15/26.
//

import Foundation

/// "오늘의 Pické — 투표" 카드.
public struct VoteQuestion: Equatable, Identifiable {
  public let id: UUID
  public let participantCount: Int
  public let prefix: String
  public let suffix: String
  public let options: [String]

  public init(
    id: UUID = UUID(),
    participantCount: Int,
    prefix: String,
    suffix: String,
    options: [String]
  ) {
    self.id = id
    self.participantCount = participantCount
    self.prefix = prefix
    self.suffix = suffix
    self.options = options
  }
}

public extension VoteQuestion {
  static let mock = VoteQuestion(
    participantCount: 985,
    prefix: "도덕의 기준은",
    suffix: "이다",
    options: ["결과", "의도", "규칙", "덕"]
  )
}
