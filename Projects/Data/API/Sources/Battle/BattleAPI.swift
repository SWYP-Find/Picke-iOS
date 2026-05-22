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
  case perspectives(battleId: Int)
  case myPerspective(battleId: Int)

  public var description: String {
    switch self {
    case let .detail(battleId):
      return "\(battleId)"
    case let .preVote(battleId):
      return "\(battleId)/votes/pre"
    case let .postVote(battleId):
      return "\(battleId)/votes/post"
    case let .scenario(battleId):
      return "\(battleId)/scenario"
    case let .voteStats(battleId):
      return "\(battleId)/vote-stats"
    case let .perspectives(battleId):
      return "\(battleId)/perspectives"
    case let .myPerspective(battleId):
      return "\(battleId)/perspectives/me"
    }
  }
}
