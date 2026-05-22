//
//  QuizQuestion.swift
//  Entity
//
//  Created by Wonji Suh  on 5/15/26.
//

import Foundation

/// "오늘의 Pické — 퀴즈" 카드 — API 의 todayQuizzes.
public struct QuizQuestion: Equatable, Identifiable {
  public let battleId: Int
  public let title: String
  public let summary: String
  public let participantCount: Int
  public let itemA: String
  public let itemADesc: String
  public let isCorrectA: Bool
  public let itemB: String
  public let itemBDesc: String
  public let isCorrectB: Bool

  public var id: Int { battleId }

  public init(
    battleId: Int,
    title: String,
    summary: String,
    participantCount: Int,
    itemA: String,
    itemADesc: String,
    isCorrectA: Bool,
    itemB: String,
    itemBDesc: String,
    isCorrectB: Bool
  ) {
    self.battleId = battleId
    self.title = title
    self.summary = summary
    self.participantCount = participantCount
    self.itemA = itemA
    self.itemADesc = itemADesc
    self.isCorrectA = isCorrectA
    self.itemB = itemB
    self.itemBDesc = itemBDesc
    self.isCorrectB = isCorrectB
  }
}

public extension QuizQuestion {
  static let mock = QuizQuestion(
    battleId: 31,
    title: "AI가 만든 그림도 '예술 작품'으로 인정해야 할까?",
    summary: "인간의 창의성 없이 생성된 결과물도 예술로 볼 수 있을까요?\n지금 바로 당신의 입장을 선택하세요",
    participantCount: 1340,
    itemA: "O 정답", itemADesc: "explanation", isCorrectA: true,
    itemB: "X 오답", itemBDesc: "explanation", isCorrectB: false
  )
}
