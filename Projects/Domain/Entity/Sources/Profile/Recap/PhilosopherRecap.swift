//
//  PhilosopherRecap.swift
//  Entity
//
//  `GET /api/v1/me/recap` 응답 — 나의 철학자 유형 리캡.
//

import Foundation

public struct PhilosopherRecap: Equatable {
  public let myCard: RecapCard
  public let bestMatchCard: RecapCard
  public let worstMatchCard: RecapCard
  public let scores: RecapScores
  public let preferenceReport: PreferenceReport

  public init(
    myCard: RecapCard,
    bestMatchCard: RecapCard,
    worstMatchCard: RecapCard,
    scores: RecapScores,
    preferenceReport: PreferenceReport
  ) {
    self.myCard = myCard
    self.bestMatchCard = bestMatchCard
    self.worstMatchCard = worstMatchCard
    self.scores = scores
    self.preferenceReport = preferenceReport
  }
}
