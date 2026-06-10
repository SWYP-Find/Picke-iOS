//
//  PieckeDomain.swift
//  API
//
//  Created by Wonji Suh  on 12/29/25.
//

import Foundation

import AsyncMoya

public enum PieckeDomain {
  case auth
  case profile
  case home
  case poll
  case battle
  case comment
  case perspective
  case search
  case notification
}

extension PieckeDomain: DomainType {
  public var baseURLString: String {
    BaseAPI.base.apiDescription
  }

  public var url: String {
    switch self {
    case .auth:
      return "api/v1/auth/"
    case .profile:
      return "api/v1/me/"
    case .home:
      return "api/v1/home"
    case .poll:
      return "api/v1/poll"
    case .battle:
      return "api/v1/battles/"
    case .comment:
      return "api/v1/comments/"
    case .perspective:
      return "api/v1/perspectives/"
    case .search:
      return "api/v1/search/"
    case .notification:
      return "api/v1/notifications"
    }
  }
}
