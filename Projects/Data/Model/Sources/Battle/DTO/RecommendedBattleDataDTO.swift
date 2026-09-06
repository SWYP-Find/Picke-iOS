//
//  RecommendedBattleDataDTO.swift
//  Model
//

import Foundation

public struct RecommendedBattlePageDataDTO: Decodable {
  public let items: [RecommendedBattleDTO]
  public let nextCursor: String?
  public let hasNext: Bool
}

public struct RecommendedBattleDTO: Decodable {
  public let battleId: Int
  public let title: String?
  public let summary: String?
  public let audioDuration: Int?
  public let viewCount: Int?
  public let tags: [RecommendedBattleTagDTO]?
  public let participantsCount: Int?
  public let options: [RecommendedBattleOptionDTO]?
}

public struct RecommendedBattleTagDTO: Decodable {
  public let tagId: Int
  public let name: String?
}

public struct RecommendedBattleOptionDTO: Decodable {
  public let optionId: Int
  public let title: String?
  public let stance: String?
  public let representative: String?
  public let imageUrl: String?
}

public typealias RecommendedBattlePageResponseDTO = BaseResponseDTO<RecommendedBattlePageDataDTO>
