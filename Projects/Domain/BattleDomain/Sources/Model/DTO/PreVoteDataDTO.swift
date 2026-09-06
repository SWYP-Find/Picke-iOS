//
//  PreVoteDataDTO.swift
//  BattleDomain
//

import Foundation

public struct PreVoteDataDTO: Decodable {
  public let voteId: Int
  public let status: String
}

public typealias PreVoteResponseDTO = BaseResponseDTO<PreVoteDataDTO>
