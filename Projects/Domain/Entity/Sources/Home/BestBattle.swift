//
//  BestBattle.swift
//  Entity
//
//  Created by Wonji Suh on 5/15/26.
//

import Foundation

/// "Best 배틀" 랭킹 리스트 아이템.
public struct BestBattle: Equatable, Identifiable {
  public let id: UUID
  public let rank: Int
  public let pair: String
  public let title: String
  public let categories: [String]
  public let durationMinutes: Int
  public let viewCount: Int

  public init(
    id: UUID = UUID(),
    rank: Int,
    pair: String,
    title: String,
    categories: [String],
    durationMinutes: Int,
    viewCount: Int
  ) {
    self.id = id
    self.rank = rank
    self.pair = pair
    self.title = title
    self.categories = categories
    self.durationMinutes = durationMinutes
    self.viewCount = viewCount
  }
}

public extension BestBattle {
  static let mocks: [BestBattle] = [
    .init(
      rank: 1,
      pair: "맹자 VS 순자",
      title: "인간은 본래 선한가, 악한가?",
      categories: ["#철학", "#인문"],
      durationMinutes: 8,
      viewCount: 1340
    ),
    .init(
      rank: 2,
      pair: "칸트 VS 톨스토이",
      title: "죽음을 앞둔 사람에게 진실을 말해야 하는가?",
      categories: ["#철학", "#인문"],
      durationMinutes: 8,
      viewCount: 1340
    ),
    .init(
      rank: 3,
      pair: "튜링 VS 설",
      title: "AI와 사랑에 빠지는 것, 진짜 사랑인가?",
      categories: ["#철학", "#인문"],
      durationMinutes: 8,
      viewCount: 1340
    ),
  ]
}
