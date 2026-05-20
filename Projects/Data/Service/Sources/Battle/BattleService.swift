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
}

extension BattleService: BaseTargetType {
  public typealias Domain = PieckeDomain

  public var domain: PieckeDomain { .battle }

  public var urlPath: String {
    switch self {
    case let .preVote(battleId, _):
      BattleAPI.preVote(battleId: battleId).description
    }
  }

  public var error: [Int: AsyncMoya.NetworkError]? { nil }

  public var method: Moya.Method {
    switch self {
    case .preVote:
      .post
    }
  }

  public var parameters: [String: Any]? {
    switch self {
    case let .preVote(_, body):
      body.toDictionary
    }
  }

  public var headers: [String: String]? {
    APIHeader.baseHeader
  }
}

public struct PreVoteRequest: Encodable {
  public let optionId: Int

  public init(optionId: Int) {
    self.optionId = optionId
  }
}
