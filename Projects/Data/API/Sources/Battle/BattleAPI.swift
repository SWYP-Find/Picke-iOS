//
//  BattleAPI.swift
//  API
//

import Foundation

public enum BattleAPI {
  case preVote(battleId: Int)
  case scenario(battleId: Int)

  public var description: String {
    switch self {
    case let .preVote(battleId):
      "\(battleId)/votes/pre"
    case let .scenario(battleId):
      "\(battleId)/scenario"
    }
  }
}
