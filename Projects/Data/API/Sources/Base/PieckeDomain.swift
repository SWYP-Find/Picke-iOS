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
 
}

extension PieckeDomain: DomainType {
  public var baseURLString: String {
    return BaseAPI.base.apiDescription
  }
  
  public var url: String {
    switch self {
    case .auth:
      return "api/v1/auth/"
    case .profile:
      return "api/v1/me/"
    
    }
  }
}
