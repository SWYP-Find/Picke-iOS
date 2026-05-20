//
//  BattleDetailDataDTO.swift
//  Model
//

import Foundation

public struct BattleDetailDataDTO: Decodable {
  public let battleInfo: BattleInfoDTO
  public let description: String
  public let shareUrl: String
  public let userVoteStatus: String
  public let currentStep: String
  public let categoryTags: [BattleTagDTO]
  public let philosopherTags: [BattleTagDTO]
  public let valueTags: [BattleTagDTO]
}

public struct BattleInfoDTO: Decodable {
  public let battleId: Int
  public let title: String
  public let summary: String
  public let thumbnailUrl: String
  public let viewCount: Int
  public let participantsCount: Int
  public let audioDuration: Int
  public let tags: [BattleTagDTO]
  public let options: [BattleOptionDTO]
}

public struct BattleOptionDTO: Decodable {
  public let optionId: Int
  public let label: String
  public let title: String
  public let stance: String
  public let representative: String
  public let imageUrl: String
  public let tags: [BattleTagDTO]
}

public struct BattleTagDTO: Decodable {
  public let tagId: Int
  public let name: String
  public let type: String
}

public typealias BattleDetailResponseDTO = BaseResponseDTO<BattleDetailDataDTO>
