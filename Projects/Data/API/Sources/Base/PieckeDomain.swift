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
}

extension PieckeDomain: DomainType {
  public var baseURLString: String {
    BaseAPI.base.apiDescription
  }

  public var url: String {
    switch self {
    case .auth:
      "api/v1/auth/"
    case .profile:
      "api/v1/me/"
    case .home:
      "api/v1/home"
    case .poll:
      "api/v1/poll"
    case .battle:
      "api/v1/battles/"
    case .comment:
      "api/v1/comments/"
    }
  }
}
