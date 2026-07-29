//
//  TodayBattleDataDTO.swift
//  Model
//

import Foundation

public struct TodayBattlePageDataDTO: Decodable {
  public let items: [BattleInfoDTO]
  public let totalCount: Int
}

public typealias TodayBattlePageResponseDTO = BaseResponseDTO<TodayBattlePageDataDTO>
