//
//  VoteSummary.swift
//  Entity
//
//  댓글 화면 상단 투표 통계 모델.
//

import Foundation

public struct VoteSummary: Equatable {
  public var changeBadgeTitle: String
  public var optionA: VoteOptionSummary
  public var optionB: VoteOptionSummary

  public init(
    changeBadgeTitle: String,
    optionA: VoteOptionSummary,
    optionB: VoteOptionSummary
  ) {
    self.changeBadgeTitle = changeBadgeTitle
    self.optionA = optionA
    self.optionB = optionB
  }

  public static let mock = VoteSummary(
    changeBadgeTitle: "생각이 바뀌었어요",
    optionA: .init(label: "A", title: "변기는 변기다", representative: "플라톤", percentage: 0.595),
    optionB: .init(label: "B", title: "예술이다", representative: "사르트르", percentage: 0.405)
  )

  public static let empty = VoteSummary(
    changeBadgeTitle: "생각이 바뀌었어요",
    optionA: .init(label: "A", title: "", representative: "", percentage: 0),
    optionB: .init(label: "B", title: "", representative: "", percentage: 0)
  )
}
