//
//  BattleProposalDataDTO.swift
//  BattleDomain
//

import Foundation

import PickeNetworkInterface

public struct BattleProposalDataDTO: Decodable {
  public let id: Int?
  public let userId: Int?
  public let nickname: String?
  public let category: String?
  public let topic: String?
  public let positionA: String?
  public let positionB: String?
  public let description: String?
  public let status: String?
  public let createdAt: String?
}
