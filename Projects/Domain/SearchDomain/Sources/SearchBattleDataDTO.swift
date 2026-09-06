//
//  SearchBattleDataDTO.swift
//  SearchDomain
//

import PickeNetworkInterface
import Foundation


public struct SearchBattlePageDataDTO: Decodable {
  public let items: [SearchBattleDTO]
  public let nextOffset: Int?
  public let hasNext: Bool
}

public struct SearchBattleDTO: Decodable {
  public let battleId: Int
  public let thumbnailUrl: String?
  public let title: String?
  public let summary: String?
  public let tags: [SearchBattleTagDTO]?
  public let audioDuration: Int?
  public let viewCount: Int?
}

public struct SearchBattleTagDTO: Decodable {
  public let tagId: Int
  public let name: String?
  public let type: String?
}

public typealias SearchBattlePageResponseDTO = BaseResponseDTO<SearchBattlePageDataDTO>
