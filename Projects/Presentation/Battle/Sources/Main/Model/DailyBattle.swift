//
//  DailyBattle.swift
//  Battle
//
//  오늘의 배틀 화면 모델 — picke.pen `오늘의 배틀`. `BattleInfo` 에서 매핑.
//

import Foundation

import Entity
import Utill

public struct DailyBattle: Equatable, Identifiable {
  public var battleId: Int
  public var imageURL: String?
  public var tags: [String]
  public var title: String
  public var question: String
  public var durationText: String
  public var options: [Option]

  public var id: Int { battleId }

  public init(
    battleId: Int,
    imageURL: String?,
    tags: [String],
    title: String,
    question: String,
    durationText: String,
    options: [Option]
  ) {
    self.battleId = battleId
    self.imageURL = imageURL
    self.tags = tags
    self.title = title
    self.question = question
    self.durationText = durationText
    self.options = options
  }

  /// 세로 카드 한 장 (대표자 / 입장 / 인용구).
  public struct Option: Equatable, Identifiable {
    public let id: Int
    public var representative: String
    public var stance: String
    public var quote: String

    public init(
      id: Int,
      representative: String,
      stance: String,
      quote: String
    ) {
      self.id = id
      self.representative = representative
      self.stance = stance
      self.quote = quote
    }
  }

  /// 서버 `BattleInfo`(오늘의 배틀 아이템) → 화면 모델 매핑.
  public static func from(_ info: BattleInfo) -> DailyBattle {
    DailyBattle(
      battleId: info.battleId,
      imageURL: info.thumbnailUrl.isEmpty ? nil : info.thumbnailUrl,
      tags: info.tags.map(\.name),
      title: info.title,
      question: info.summary,
      durationText: info.audioDuration.durationText,
      options: info.options.prefix(2).map {
        // API title = 짧은 입장 라벨("선하다"), API stance = 설명 문장(긴 인용구).
        Option(id: $0.optionId, representative: $0.representative, stance: $0.title, quote: $0.stance)
      }
    )
  }
}
