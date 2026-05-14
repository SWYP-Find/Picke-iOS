//
//  AuthApI.swift
//  API
//
//  Created by Wonji Suh  on 5/14/26.
//

import Foundation

public enum AuthAPI: String, CaseIterable {
  case login
  case refresh
  case withDraw
  case logout
  
  public var description: String {
    switch self {
    case .login:
      return "login"
    case .refresh:
      return "refresh"
    case .withDraw:
      return "withdraw"
    case .logout:
      return "logout"
    }
  }
}
