//
//  NewBattle.swift
//  Entity
//
//  Created by Wonji Suh  on 5/15/26.
//

import Foundation
import CommonDomainInterface

/// "새로운 배틀" 리스트 아이템 — API 의 newBattles.
public struct NewBattle: Equatable, Identifiable {
  public let battleId: Int
  public let thumbnailURL: URL?
  public let title: String
  public let summary: String
  public let philosopherA: String
  public let optionATitle: String
  public let philosopherAImageURL: URL?
  public let philosopherB: String
  public let optionBTitle: String
  public let philosopherBImageURL: URL?
  public let tags: [BattleTag]
  public let audioDuration: Int
  public let viewCount: Int

  public var id: Int { battleId }

  public init(
    battleId: Int,
    thumbnailURL: URL? = nil,
    title: String,
    summary: String,
    philosopherA: String,
    optionATitle: String,
    philosopherAImageURL: URL? = nil,
    philosopherB: String,
    optionBTitle: String,
    philosopherBImageURL: URL? = nil,
    tags: [BattleTag] = [],
    audioDuration: Int,
    viewCount: Int
  ) {
    self.battleId = battleId
    self.thumbnailURL = thumbnailURL
    self.title = title
    self.summary = summary
    self.philosopherA = philosopherA
    self.optionATitle = optionATitle
    self.philosopherAImageURL = philosopherAImageURL
    self.philosopherB = philosopherB
    self.optionBTitle = optionBTitle
    self.philosopherBImageURL = philosopherBImageURL
    self.tags = tags
    self.audioDuration = audioDuration
    self.viewCount = viewCount
  }

  public var durationMinutes: Int { max(1, audioDuration / 60) }
}

public extension NewBattle {
  static let mocks: [NewBattle] = [
    .init(
      battleId: 51,
      thumbnailURL: URL(string: "https://picsum.photos/seed/picke-new-1/400/200"),
      title: "인간은 본래 선한가, 악한가?",
      summary: "인간 본성의 선악과 문명의 역할에 관한 철학적 대결!",
      philosopherA: "순자",
      optionATitle: "악하다",
      philosopherAImageURL: URL(string: "https://picsum.photos/seed/picke-philo-a/80/80"),
      philosopherB: "순자",
      optionBTitle: "악하다",
      philosopherBImageURL: URL(string: "https://picsum.photos/seed/picke-philo-b/80/80"),
      tags: [.init(tagId: 501, name: "#철학", type: .category)],
      audioDuration: 5 * 60, viewCount: 726
    ),
    .init(
      battleId: 52,
      thumbnailURL: URL(string: "https://picsum.photos/seed/picke-new-2/400/200"),
      title: "노키즈존: 영업상의 자유인가, 공공장소에서의 차별인가?",
      summary: "옆 테이블 아이의 울음소리가 평화로운 휴식시간을 깨뜨린다면?",
      philosopherA: "순자",
      optionATitle: "악하다",
      philosopherAImageURL: URL(string: "https://picsum.photos/seed/picke-philo-a/80/80"),
      philosopherB: "순자",
      optionBTitle: "악하다",
      philosopherBImageURL: URL(string: "https://picsum.photos/seed/picke-philo-b/80/80"),
      tags: [.init(tagId: 502, name: "#사회", type: .category)],
      audioDuration: 5 * 60, viewCount: 726
    ),
    .init(
      battleId: 53,
      thumbnailURL: URL(string: "https://picsum.photos/seed/picke-new-3/400/200"),
      title: "사후세계는 존재하는가, 인간이 만든 위안인가?",
      summary: "죽음은 끝일까요, 아니면 다른 방식의 시작일까요?",
      philosopherA: "순자",
      optionATitle: "악하다",
      philosopherAImageURL: URL(string: "https://picsum.photos/seed/picke-philo-a/80/80"),
      philosopherB: "순자",
      optionBTitle: "악하다",
      philosopherBImageURL: URL(string: "https://picsum.photos/seed/picke-philo-b/80/80"),
      tags: [.init(tagId: 503, name: "#철학", type: .category)],
      audioDuration: 5 * 60, viewCount: 726
    ),
  ]
}
