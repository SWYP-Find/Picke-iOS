//
//  AuthService.swift
//  Service
//
//  Created by Wonji Suh on 5/14/26.
//

import Foundation

import Alamofire
import API
import AuthDomainInterface
import PickeNetwork

public enum AuthService {
  case login(provider: SocialType, body: OAuthLoginRequest)
  case refresh(refreshToken: String)
  case withdraw(reason: String)
  case logout
}

extension AuthService: PickeDataRequest {
  public var domain: any PickeDomainType {
    switch self {
    case .login, .refresh, .logout:
      return PieckeDomain.auth
    case .withdraw:
      return PieckeDomain.profile
    }
  }

  public var path: String {
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

  public var method: HTTPMethod {
    switch self {
    case .login, .refresh, .logout:
      return .post
    case .withdraw:
      return .delete
    }
  }

  public var parameters: (any Encodable & Sendable)? {
    switch self {
    case let .login(_, body):
      return body
    case let .withdraw(reason):
      return WithdrawRequest(reason: reason)
    case .refresh, .logout:
      return nil
    }
  }

  /// withdraw 는 DELETE 지만 reason 을 JSON 바디로 보낸다(서버 규약).
  public var parameterEncoder: ParameterEncoder? {
    switch self {
    case .withdraw:
      return JSONParameterEncoder.default
    default:
      return nil
    }
  }

  public var headers: HTTPHeaders {
    switch self {
    case let .refresh(refreshToken):
      return [APIHeader.refreshToken: refreshToken]
    default:
      return [:]
    }
  }

  /// 로그인·토큰 재발급은 아직 액세스 토큰이 없거나 자기 자신이 갱신 경로다 — 인증 파이프라인을 우회한다.
  public var authorization: PickeAuthorization {
    switch self {
    case .login, .refresh:
      return .none
    case .withdraw, .logout:
      return .automatic
    }
  }
}
