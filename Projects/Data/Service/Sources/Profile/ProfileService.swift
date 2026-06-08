//
//  ProfileService.swift
//  Service
//

import Foundation

import API
import Foundations

import AsyncMoya

public enum ProfileService {
  case mypage
  case creditsHistory(query: CreditHistoryQueryRequest)
  case battleRecords(query: BattleRecordsQueryRequest)
}

extension ProfileService: BaseTargetType {
  public typealias Domain = PieckeDomain

  public var domain: PieckeDomain { .profile }

  public var urlPath: String {
    switch self {
    case .mypage:
      return ProfileAPI.mypage.description
    case .creditsHistory:
      return ProfileAPI.creditsHistory.description
    case .battleRecords:
      return ProfileAPI.battleRecords.description
    }
  }

  public var error: [Int: AsyncMoya.NetworkError]? { nil }

  public var method: Moya.Method {
    switch self {
    case .mypage, .creditsHistory, .battleRecords:
      return .get
    }
  }

  public var parameters: [String: Any]? {
    switch self {
    case .mypage:
      return nil
    case let .creditsHistory(query):
      guard let dict = query.toDictionary else { return nil }
      return dict.isEmpty ? nil : dict
    case let .battleRecords(query):
      guard let dict = query.toDictionary else { return nil }
      return dict.isEmpty ? nil : dict
    }
  }

  public var headers: [String: String]? {
    return APIHeader.baseHeader
  }
}
