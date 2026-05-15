//
//  HeroBattle.swift
//  Entity
//
//  Created by Wonji Suh on 5/15/26.
//

import Foundation

/// 홈 화면 최상단 "EDITOR PICK" 카드.
public struct HeroBattle: Equatable, Identifiable {
  public let id: UUID
  public let badge: String
  public let position: Int
  public let total: Int
  public let optionA: String
  public let optionB: String
  public let title: String
  public let subtitle: String
  public let tags: [String]
  public let viewCount: Int

  public init(
    id: UUID = UUID(),
    badge: String,
    position: Int,
    total: Int,
    optionA: String,
    optionB: String,
    title: String,
    subtitle: String,
    tags: [String],
    viewCount: Int
  ) {
    self.id = id
    self.badge = badge
    self.position = position
    self.total = total
    self.optionA = optionA
    self.optionB = optionB
    self.title = title
    self.subtitle = subtitle
    self.tags = tags
    self.viewCount = viewCount
  }
}

public extension HeroBattle {
  static let mock = HeroBattle(
    badge: "EDITOR PICK",
    position: 1,
    total: 10,
    optionA: "예술이다",
    optionB: "쓰레기다",
    title: "뒤샹의 변기, 예술인가 도발인가",
    subtitle: "뒤샹의 변기 〈샘〉은 \"무엇이 예술인가\"를 묻는 작품이다.",
    tags: ["#예술", "#현대미술"],
    viewCount: 847
  )

  static let mocks: [HeroBattle] = (1 ... 10).map { idx in
    let titles = [
      "뒤샹의 변기, 예술인가 도발인가",
      "AI가 만든 그림도 예술인가",
      "사후세계는 존재하는가",
      "노키즈존, 차별인가 자유인가",
      "안락사를 허용해야 하는가",
      "표현의 자유와 혐오 표현",
      "인간은 본래 선한가",
      "결과가 수단을 정당화하는가",
      "기억이 곧 자아인가",
      "도덕은 절대적인가 상대적인가",
    ]
    return HeroBattle(
      badge: "EDITOR PICK",
      position: idx,
      total: 10,
      optionA: idx % 2 == 0 ? "그렇다" : "예술이다",
      optionB: idx % 2 == 0 ? "아니다" : "쓰레기다",
      title: titles[idx - 1],
      subtitle: "지금 가장 뜨거운 토론 — 당신의 입장을 골라보세요.",
      tags: ["#철학", "#오늘의배틀"],
      viewCount: 847 + idx * 53
    )
  }
}
