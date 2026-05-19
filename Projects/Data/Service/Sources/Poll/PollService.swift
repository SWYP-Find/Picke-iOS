//
//  PollService.swift
//  Service
//
//  Created by Wonji Suh  on 5/19/26.
//

import Foundation

import API
import Foundations

import AsyncMoya

public enum PollService {
  case detailPoll(pollId: Int)
}

extension PollService: BaseTargetType {
  public typealias Domain = PieckeDomain

  public var domain: PieckeDomain { .poll }

  public var urlPath: String {
    switch self {
    case let .detailPoll(pollId):
      return PollAPI.detailPoll(pollId: pollId).description
    }
  }

  public var error: [Int: AsyncMoya.NetworkError]? { nil }

  public var method: Moya.Method {
    switch self {
    case .detailPoll:
      .get
    }
  }

  public var parameters: [String: Any]? { nil }

  public var headers: [String: String]? {
    APIHeader.baseHeader 
  }
}
