//
//  RecapDataDTO.swift
//  ProfileDomain
//

import PickeNetworkInterface
import Foundation

public struct RecapDataDTO: Decodable {
  public let myCard: RecapCardDTO?
  public let bestMatchCard: RecapCardDTO?
  public let worstMatchCard: RecapCardDTO?
  public let scores: RecapScoresDTO?
  public let preferenceReport: PreferenceReportDTO?
}

public struct RecapCardDTO: Decodable {
  public let philosopherType: String?
  public let philosopherLabel: String?
  public let typeName: String?
  public let description: String?
  public let keywordTags: [String]?
  public let imageUrl: String?
}

public struct RecapScoresDTO: Decodable {
  public let principle: Double?
  public let reason: Double?
  public let individual: Double?
  public let change: Double?
  public let inner: Double?
  public let ideal: Double?
}

public struct PreferenceReportDTO: Decodable {
  public let totalParticipation: Int?
  public let opinionChanges: Int?
  public let battleWinRate: Int?
  public let favoriteTopics: [FavoriteTopicDTO]?
}

public struct FavoriteTopicDTO: Decodable {
  public let rank: Int?
  public let participationCount: Int?
  public let tagName: String?
}
