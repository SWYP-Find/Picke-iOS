//
//  BattleAPI.swift
//  API
//

import Foundation

public enum BattleAPI {
  case detail(battleId: Int)
  case preVote(battleId: Int)
  case postVote(battleId: Int)
  case scenario(battleId: Int)
  case voteStats(battleId: Int)

  public var description: String {
    switch self {
    case let .detail(battleId):
      "\(battleId)"
    case let .preVote(battleId):
      "\(battleId)/votes/pre"
    case let .postVote(battleId):
      "\(battleId)/votes/post"
    case let .scenario(battleId):
      "\(battleId)/scenario"
    case let .voteStats(battleId):
      "\(battleId)/vote-stats"
    }
  }
}
