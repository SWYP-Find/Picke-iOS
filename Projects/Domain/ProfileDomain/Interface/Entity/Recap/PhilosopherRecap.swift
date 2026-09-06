//
//  PhilosopherRecap.swift
//  Entity
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

  /// 잠금/빈 응답용 — totalParticipation 0 → 잠금 판정.
  public static let empty = PhilosopherRecap(
    myCard: .empty,
    bestMatchCard: .empty,
    worstMatchCard: .empty,
    scores: .empty,
    preferenceReport: .empty
  )
}
