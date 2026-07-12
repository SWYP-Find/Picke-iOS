//
//  PreferenceReport.swift
//  Entity
//
//  내 취향 리포트 (통계 + 선호 주제 랭킹).
//

import Foundation

public struct PreferenceReport: Equatable {
  public let totalParticipation: Int
  public let opinionChanges: Int
  /// 배틀 승률 (%).
  public let battleWinRate: Int
  public let favoriteTopics: [FavoriteTopic]

  public init(
    totalParticipation: Int,
    opinionChanges: Int,
    battleWinRate: Int,
    favoriteTopics: [FavoriteTopic]
  ) {
    self.totalParticipation = totalParticipation
    self.opinionChanges = opinionChanges
    self.battleWinRate = battleWinRate
    self.favoriteTopics = favoriteTopics
  }

  public static let empty = PreferenceReport(
    totalParticipation: 0,
    opinionChanges: 0,
    battleWinRate: 0,
    favoriteTopics: []
  )
}
