//
//  BattleService.swift
//  Service
//

import Foundation

import API
import Foundations

import AsyncMoya

public struct CreatePerspectiveRequest: Encodable {
  public let content: String
  public let optionId: Int
  public init(content: String, optionId: Int) {
    self.content = content
    self.optionId = optionId
  }
}

public enum BattleService {
  case detail(battleId: Int)
  case preVote(battleId: Int, body: PreVoteRequest)
  case postVote(battleId: Int, body: PreVoteRequest)
  case scenario(battleId: Int)
  case voteStats(battleId: Int)
  case perspectives(battleId: Int, cursor: String?, size: Int?, optionLabel: String?, sort: String?)
  case createPerspective(battleId: Int, body: CreatePerspectiveRequest)
}

extension BattleService: BaseTargetType {
  public typealias Domain = PieckeDomain

  public var domain: PieckeDomain { .battle }

  public var urlPath: String {
    switch self {
    case let .detail(battleId):
      BattleAPI.detail(battleId: battleId).description
    case let .preVote(battleId, _):
      BattleAPI.preVote(battleId: battleId).description
    case let .postVote(battleId, _):
      BattleAPI.postVote(battleId: battleId).description
    case let .scenario(battleId):
      BattleAPI.scenario(battleId: battleId).description
    case let .voteStats(battleId):
      BattleAPI.voteStats(battleId: battleId).description
    case let .perspectives(battleId, _, _, _, _):
      BattleAPI.perspectives(battleId: battleId).description
    case let .createPerspective(battleId, _):
      BattleAPI.perspectives(battleId: battleId).description
    }
  }

  public var error: [Int: AsyncMoya.NetworkError]? { nil }

  public var method: Moya.Method {
    switch self {
    case .detail:
      .get
    case .preVote:
      .post
    case .postVote:
      .post
    case .scenario:
      .get
    case .voteStats:
      .get
    case .perspectives:
      .get
    case .createPerspective:
      .post
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
    case let .perspectives(_, cursor, size, optionLabel, sort):
      var query: [String: Any] = [:]
      if let cursor { query["cursor"] = cursor }
      if let size { query["size"] = size }
      if let optionLabel { query["optionLabel"] = optionLabel }
      if let sort { query["sort"] = sort }
      return query.isEmpty ? nil : query
    case let .createPerspective(_, body):
      return body.toDictionary
    }
  }

  public var headers: [String: String]? {
    APIHeader.baseHeader
  }
}
