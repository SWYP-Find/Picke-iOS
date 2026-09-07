//
//  PreVoteDataDTO.swift
//  BattleDomain
//

import Foundation

import PickeNetworkInterface

public struct PreVoteDataDTO: Decodable {
  public let voteId: Int
  public let status: String
}
