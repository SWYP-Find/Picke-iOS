//
//  BattleService.swift
//  Service
//

import Foundation

import API
import Foundations

import AsyncMoya

public enum BattleService {
  case detail(battleId: Int)
  case preVote(battleId: Int, body: PreVoteRequest)
  case postVote(battleId: Int, body: PreVoteRequest)
  case scenario(battleId: Int)
  case voteStats(battleId: Int)
  case perspectives(battleId: Int, query: PerspectivesQueryRequest)
  case createPerspective(battleId: Int, body: CreatePerspectiveRequest)
  case myPerspective(battleId: Int)
  case recommendations(battleId: Int)
}

extension BattleService: BaseTargetType {
  public typealias Domain = PieckeDomain

  public var domain: PieckeDomain { .battle }

  public var urlPath: String {
    switch self {
    case let .detail(battleId):
      return BattleAPI.detail(battleId: battleId).description
    case let .preVote(battleId, _):
      return BattleAPI.preVote(battleId: battleId).description
    case let .postVote(battleId, _):
      return BattleAPI.postVote(battleId: battleId).description
    case let .scenario(battleId):
      return BattleAPI.scenario(battleId: battleId).description
    case let .voteStats(battleId):
      return BattleAPI.voteStats(battleId: battleId).description
    case let .perspectives(battleId, _):
      return BattleAPI.perspectives(battleId: battleId).description
    case let .createPerspective(battleId, _):
      return BattleAPI.perspectives(battleId: battleId).description
    case let .myPerspective(battleId):
      return BattleAPI.myPerspective(battleId: battleId).description
    case let .recommendations(battleId):
      return BattleAPI.recommendations(battleId: battleId).description
    }
  }

  public var error: [Int: AsyncMoya.NetworkError]? { nil }

  public var method: Moya.Method {
    switch self {
    case .detail, .scenario, .voteStats, .perspectives, .myPerspective, .recommendations:
      return .get
    case .preVote, .postVote, .createPerspective:
      return .post
    }
  }

  public var parameters: [String: Any]? {
    switch self {
    case .detail:
      return nil
    case let .preVote(_, body):
      return body.toDictionary
    case let .postVote(_, body):
      return body.toDictionary
    case .scenario:
      return nil
    case .voteStats:
      return nil
    case let .perspectives(_, query):
      guard let dict = query.toDictionary else { return nil }
      return dict.isEmpty ? nil : dict
    case let .createPerspective(_, body):
      return body.toDictionary
    case .myPerspective:
      return nil
    case .recommendations:
      return nil
    }
  }

  public var headers: [String: String]? {
    return APIHeader.baseHeader
  }
}
