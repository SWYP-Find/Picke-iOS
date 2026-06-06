//
//  TodayBattleDataDTO.swift
//  Model
//
//  `GET /api/v1/battles/today` 응답 DTO. 아이템은 BattleInfoDTO 재사용.
//

import Foundation

public struct TodayBattlePageDataDTO: Decodable {
  public let items: [BattleInfoDTO]
  public let totalCount: Int
}

public typealias TodayBattlePageResponseDTO = BaseResponseDTO<TodayBattlePageDataDTO>
