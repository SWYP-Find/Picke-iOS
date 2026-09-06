//
//  UserSession.swift
//  Entity
//
//  Created by Wonji Suh  on 5/14/26.
//

import Foundation

public struct UserSession: Equatable {
  public var name: String
  public var provider: SocialType
  public var token: String
  public var accessToken: String
  public var oauthRefreshToken: String?
  
  public init(
    name: String = "",
    provider: SocialType = .apple,
    token: String = "",
    accessToken: String = "",
    oauthRefreshToken: String? = nil,
    inviteCode: String = "",
    generation: String = ""
  ) {
    self.name = name
    self.provider = provider
    self.token = token
    self.accessToken = accessToken
    self.oauthRefreshToken = oauthRefreshToken
  }
  
}


public extension UserSession {
  static let empty = UserSession()
}
