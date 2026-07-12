//
//  AuthService.swift
//  Service
//
//  Created by Wonji Suh on 5/14/26.
//

import Foundation

import API
import Entity
import NetworkHeader

import AsyncMoya

public enum AuthService {
  case login(provider: SocialType, body: OAuthLoginRequest)
  case refresh(refreshToken: String)
  case withdraw(token: String)
  case logout
}

extension AuthService: BaseTargetType {
  public typealias Domain = PieckeDomain

  public var domain: PieckeDomain {
    switch self {
    case .login, .refresh, .logout:
      return .auth
    case .withdraw:
      return .profile
    }
  }

  public var urlPath: String {
    switch self {
    case let .login(provider, _):
      return "\(AuthAPI.login.description)/\(provider.rawValue)"
    case .refresh:
      return AuthAPI.refresh.description
    case .withdraw:
      return AuthAPI.withDraw.description
    case .logout:
      return AuthAPI.logout.description
    }
  }

  public var error: [Int: AsyncMoya.NetworkError]? {
    nil
  }

  public var method: Moya.Method {
    switch self {
    case .login, .refresh, .logout:
      return .post
    case .withdraw:
      return .delete
    }
  }

  public var parameters: [String: Any]? {
    switch self {
    case let .login(_, body):
      return body.toDictionary
    case .refresh:
      return nil
    case let .withdraw(token):
      return token.toDictionary(key: "token")
    case .logout:
      return nil
    }
  }

  public var headers: [String: String]? {
    switch self {
    case let .refresh(refreshToken):
      var headers = APIHeader.notAccessTokenHeader
      headers[APIHeader.refreshToken] = refreshToken
      return headers
    case .withdraw, .logout:
      return APIHeader.baseHeader
    default:
      return APIHeader.notAccessTokenHeader
    }
  }
}
