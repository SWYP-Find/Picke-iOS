//
//  QuizQuestion.swift
//  Entity
//
//  Created by Wonji Suh on 5/15/26.
//

import Foundation

/// "오늘의 Pické — 퀴즈" 카드.
public struct QuizQuestion: Equatable, Identifiable {
  public let id: UUID
  public let participantCount: Int
  public let title: String
  public let subtitle: String
  public let optionA: String
  public let optionB: String

  public init(
    id: UUID = UUID(),
    participantCount: Int,
    title: String,
    subtitle: String,
    optionA: String,
    optionB: String
  ) {
    self.id = id
    self.participantCount = participantCount
    self.title = title
    self.subtitle = subtitle
    self.optionA = optionA
    self.optionB = optionB
  }
}

public extension QuizQuestion {
  static let mock = QuizQuestion(
    participantCount: 1340,
    title: "AI가 만든 그림도 '예술 작품'으로 인정해야 할까?",
    subtitle: "인간의 창의성 없이 생성된 결과물도 예술로 볼 수 있을까요?\n지금 바로 당신의 입장을 선택하세요",
    optionA: "O 정답",
    optionB: "X 오답"
  )
}
