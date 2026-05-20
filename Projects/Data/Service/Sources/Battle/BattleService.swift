//
//  BattleService.swift
//  Service
//

import Foundation

import API
import Foundations

import AsyncMoya

public enum BattleService {
  case preVote(battleId: Int, body: PreVoteRequest)
  case scenario(battleId: Int)
}

extension BattleService: BaseTargetType {
  public typealias Domain = PieckeDomain

  public var domain: PieckeDomain { .battle }

  public var urlPath: String {
    switch self {
    case let .preVote(battleId, _):
      return BattleAPI.preVote(battleId: battleId).description
    case let .scenario(battleId):
      return BattleAPI.scenario(battleId: battleId).description
    }
  }

  public var error: [Int: AsyncMoya.NetworkError]? { nil }

  public var method: Moya.Method {
    switch self {
    case .preVote:
      return .post
    case .scenario:
      return .get
    }
  }

  public var parameters: [String: Any]? {
    switch self {
    case let .preVote(_, body):
    return  body.toDictionary
    case .scenario:
      return nil
    }
  }

  public var headers: [String: String]? {
    return APIHeader.baseHeader
  }
}
