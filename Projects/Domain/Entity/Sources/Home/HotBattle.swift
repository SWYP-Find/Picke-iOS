//
//  HotBattle.swift
//  Entity
//
//  Created by Wonji Suh on 5/15/26.
//

import Foundation

/// "지금 뜨는 배틀" 가로 스크롤 카드.
public struct HotBattle: Equatable, Identifiable {
  public let id: UUID
  public let tag: String
  public let title: String
  public let durationMinutes: Int
  public let viewCount: Int

  public init(
    id: UUID = UUID(),
    tag: String,
    title: String,
    durationMinutes: Int,
    viewCount: Int
  ) {
    self.id = id
    self.tag = tag
    self.title = title
    self.durationMinutes = durationMinutes
    self.viewCount = viewCount
  }
}

public extension HotBattle {
  static let mocks: [HotBattle] = [
    .init(tag: "#철학", title: "인간은 본래 선한가, 악한가?", durationMinutes: 8, viewCount: 1340),
    .init(tag: "#역사", title: "안락사 도입, 당신의 입장은?", durationMinutes: 5, viewCount: 1132),
    .init(tag: "#사회", title: "노키즈존, 영업의 자유인가?", durationMinutes: 5, viewCount: 902),
    .init(tag: "#과학", title: "AI는 의식을 가질 수 있는가?", durationMinutes: 6, viewCount: 780),
  ]
}
