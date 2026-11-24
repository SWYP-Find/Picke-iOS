//
//  PreVoteDataDTO.swift
//  BattleDomain
//
//  Created by Picke on 10/11/26.
//

import Foundation

import PickeNetworkInterface

public struct PreVoteDataDTO: Decodable {
  public let voteId: Int
  public let status: String
}
