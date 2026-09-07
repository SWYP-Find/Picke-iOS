//
//  TodayBattleDataDTO.swift
//  BattleDomain
//

import Foundation

import PickeNetworkInterface

public struct TodayBattlePageDataDTO: Decodable {
  public let items: [BattleInfoDTO]
  public let totalCount: Int
}
