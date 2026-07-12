//
//  HomeService.swift
//  Service
//
//  Created by Wonji Suh on 5/16/26.
//

import Foundation

import API
import NetworkHeader

import AsyncMoya

public enum HomeService {
  case home
}

extension HomeService: BaseTargetType {
  public typealias Domain = PieckeDomain

  public var domain: PieckeDomain { .home }

  public var urlPath: String {
    switch self {
    case .home:
      return HomeAPI.home.description
    }
  }

  public var error: [Int: AsyncMoya.NetworkError]? { nil }

  public var method: Moya.Method {
    switch self {
    case .home:
      return .get
    }
  }

  public var parameters: [String: Any]? { nil }

  public var headers: [String: String]? {
    return APIHeader.baseHeader // 인증 헤더 포함 (액세스 토큰)
  }
}
