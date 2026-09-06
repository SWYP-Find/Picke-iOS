//
//  BattleRecordDataDTO.swift
//  ProfileDomain
//

import PickeNetworkInterface
import Foundation

public struct BattleRecordDataDTO: Decodable {
  public let items: [BattleRecordItemDTO]?
  public let nextOffset: Int?
  public let hasNext: Bool?
}

public struct BattleRecordItemDTO: Decodable {
  public let battleId: String?
  public let recordId: String?
  public let voteSide: String?
  public let category: String?
  public let title: String?
  public let summary: String?
  public let createdAt: String?
}

public typealias BattleRecordResponseDTO = BaseResponseDTO<BattleRecordDataDTO>
