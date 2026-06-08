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
    }
  }

  public var error: [Int: AsyncMoya.NetworkError]? { nil }

  public var method: Moya.Method {
    switch self {
    case .mypage, .creditsHistory:
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
    }
  }

  public var headers: [String: String]? {
    return APIHeader.baseHeader
  }
}
