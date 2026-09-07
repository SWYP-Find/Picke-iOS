//
//  BattleService.swift
//  Service
//

import Foundation

import API
import PickeNetwork

public enum BattleService {
  case today
  case detail(battleId: Int)
  case preVote(battleId: Int, body: PreVoteRequest)
  case postVote(battleId: Int, body: PreVoteRequest)
  case scenario(battleId: Int)
  case voteStats(battleId: Int)
  case perspectives(battleId: Int, query: PerspectivesQueryRequest)
  case createPerspective(battleId: Int, body: CreatePerspectiveRequest)
  case myPerspective(battleId: Int)
  case recommendations(battleId: Int)
  case createProposal(body: BattleProposalRequest)
}

extension BattleService: PickeDataRequest {
  public var domain: any PickeDomainType { PieckeDomain.battle }

  public var path: String {
    switch self {
    case .today:
      return BattleAPI.today.description
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
    case .createProposal:
      return BattleAPI.proposals.description
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .today, .detail, .scenario, .voteStats, .perspectives, .myPerspective, .recommendations:
      return .get
    case .preVote, .postVote, .createPerspective, .createProposal:
      return .post
    }
  }

  public var parameters: (any Encodable & Sendable)? {
    switch self {
    case let .preVote(_, body):
      return body
    case let .postVote(_, body):
      return body
    case let .perspectives(_, query):
      return query
    case let .createPerspective(_, body):
      return body
    case let .createProposal(body):
      return body
    case .today, .detail, .scenario, .voteStats, .myPerspective, .recommendations:
      return nil
    }
  }
}
