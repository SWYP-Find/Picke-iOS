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

public struct VoteOptionSummary: Equatable {
  public var label: String
  public var title: String
  public var representative: String
  public var percentage: Double

  public init(
    label: String,
    title: String,
    representative: String,
    percentage: Double
  ) {
    self.label = label
    self.title = title
    self.representative = representative
    self.percentage = percentage
  }
}

public enum CommentFilter: String, CaseIterable, Equatable {
  case all
  case optionA
  case optionB

  public var title: String {
    switch self {
    case .all: "전체"
    case .optionA: "A"
    case .optionB: "B"
    }
  }

  /// 서버 쿼리에 보낼 optionLabel — `all` 은 nil.
  public var queryLabel: String? {
    switch self {
    case .all: nil
    case .optionA: "A"
    case .optionB: "B"
    }
  }
}

public enum CommentSort: String, CaseIterable, Equatable {
  case popular
  case latest

  public var title: String {
    switch self {
    case .popular: "인기순"
    case .latest: "최신순"
    }
  }

  public var perspectiveSort: BattlePerspectiveSort {
    switch self {
    case .popular: .popular
    case .latest: .latest
    }
  }
}
