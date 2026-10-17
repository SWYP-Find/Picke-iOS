//
//  TodayBattleDataDTO.swift
//  BattleDomain
//
//  Created by Picke on 10/11/26.
//

import Foundation

import PickeNetworkInterface

public struct TodayBattlePageDataDTO: Decodable {
  public let items: [BattleInfoDTO]
  public let totalCount: Int
}
