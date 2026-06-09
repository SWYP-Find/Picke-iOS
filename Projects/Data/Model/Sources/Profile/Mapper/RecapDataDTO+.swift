//
//  RecapDataDTO+.swift
//  Model
//

import Entity
import Foundation

public extension RecapDataDTO {
  func toDomain() -> PhilosopherRecap {
    PhilosopherRecap(
      myCard: myCard?.toDomain() ?? .empty,
      bestMatchCard: bestMatchCard?.toDomain() ?? .empty,
      worstMatchCard: worstMatchCard?.toDomain() ?? .empty,
      scores: scores?.toDomain() ?? .empty,
      preferenceReport: preferenceReport?.toDomain() ?? .empty
    )
  }
}

public extension RecapCardDTO {
  func toDomain() -> RecapCard {
    RecapCard(
      philosopherType: philosopherType ?? "",
      philosopherLabel: philosopherLabel ?? "",
      typeName: typeName ?? "",
      description: description ?? "",
      keywordTags: keywordTags ?? [],
      imageURL: imageUrl ?? ""
    )
  }
}

public extension RecapScoresDTO {
  func toDomain() -> RecapScores {
    RecapScores(
      principle: principle ?? 0,
      reason: reason ?? 0,
      individual: individual ?? 0,
      change: change ?? 0,
      inner: inner ?? 0,
      ideal: ideal ?? 0
    )
  }
}

public extension PreferenceReportDTO {
  func toDomain() -> PreferenceReport {
    PreferenceReport(
      totalParticipation: totalParticipation ?? 0,
      opinionChanges: opinionChanges ?? 0,
      battleWinRate: battleWinRate ?? 0,
      favoriteTopics: (favoriteTopics ?? []).map { $0.toDomain() }
    )
  }
}

public extension FavoriteTopicDTO {
  func toDomain() -> FavoriteTopic {
    FavoriteTopic(
      rank: rank ?? 0,
      tagName: tagName ?? "",
      participationCount: participationCount ?? 0
    )
  }
}

private extension RecapCard {
  static var empty: RecapCard {
    RecapCard(
      philosopherType: "",
      philosopherLabel: "",
      typeName: "",
      description: "",
      keywordTags: [],
      imageURL: ""
    )
  }
}

private extension RecapScores {
  static var empty: RecapScores {
    RecapScores(
      principle: 0,
      reason: 0,
      individual: 0,
      change: 0,
      inner: 0,
      ideal: 0
    )
  }
}

private extension PreferenceReport {
  static var empty: PreferenceReport {
    PreferenceReport(
      totalParticipation: 0,
      opinionChanges: 0,
      battleWinRate: 0,
      favoriteTopics: []
    )
  }
}
