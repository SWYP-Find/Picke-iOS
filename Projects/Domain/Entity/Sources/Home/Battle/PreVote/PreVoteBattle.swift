//
//  PreVoteBattle.swift
//  Entity
//
//  Created by Wonji Suh on 5/17/26.
//

import Foundation
import HomeDomainInterface

/// 사전 투표창 (.pen `U5WO4`) 에 표시되는 배틀 모델.
/// 홈 카드의 `VoteQuestion` 과 달리 2지선다 + 철학자 아바타 기반.
public struct PreVoteBattle: Equatable, Identifiable {
  public let battleId: Int
  public let backgroundImageURL: String?
  public let tags: [String]
  public let titleLine1: String
  public let titleLine2: String
  public let summary: String
  public let leftOption: PreVoteOption
  public let rightOption: PreVoteOption

  public var id: Int { battleId }

  public init(
    battleId: Int,
    backgroundImageURL: String?,
    tags: [String],
    titleLine1: String,
    titleLine2: String,
    summary: String,
    leftOption: PreVoteOption,
    rightOption: PreVoteOption
  ) {
    self.battleId = battleId
    self.backgroundImageURL = backgroundImageURL
    self.tags = tags
    self.titleLine1 = titleLine1
    self.titleLine2 = titleLine2
    self.summary = summary
    self.leftOption = leftOption
    self.rightOption = rightOption
  }
}

public extension PreVoteBattle {
  static let mock = PreVoteBattle(
    battleId: 41,
    backgroundImageURL: "https://picsum.photos/seed/picke-prevote/750/1024",
    tags: ["#예술", "#현대미술"],
    titleLine1: "뒤샹의 변기,",
    titleLine2: "예술인가 도발인가",
    summary: """
    누군가는 이것을 화장실의 부속품이라 부르고,
    누군가는 현대 미술의 혁명이라고 부릅니다.
    과연 이 변기의 '진짜 모습'은 무엇일까요?
    """,
    leftOption: .init(
      optionId: 1,
      representative: "플라톤",
      imageURL: "https://picke.store/api/v1/resources/images/PHILOSOPHER/plato.png",
      stance: "변기는 변기다"
    ),
    rightOption: .init(
      optionId: 2,
      representative: "사르트르",
      imageURL: "https://picke.store/api/v1/resources/images/PHILOSOPHER/sartre.png",
      stance: "예술이다"
    )
  )
}
