//
//  BattleVoteStatsDataDTO.swift
//  Model
//

import Foundation

public struct BattleVoteStatsDataDTO: Decodable {
  public let options: [BattleVoteStatsOptionDTO]
  public let totalCount: Int
  public let updatedAt: String?
}

public struct BattleVoteStatsOptionDTO: Decodable {
  public let optionId: Int
  public let label: String?
  public let title: String?
  public let isCorrect: Bool?
  public let voteCount: Int
  public let ratio: Double
  public let stance: String?
  public let imageUrl: String?
}

public typealias BattleVoteStatsResponseDTO = BaseResponseDTO<BattleVoteStatsDataDTO>
