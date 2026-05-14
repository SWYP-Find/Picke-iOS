//
//  LoginEntity.swift
//  Entity
//
//  Created by Wonji Suh  on 12/29/25.
//

import Foundation

public struct LoginEntity: Equatable {
  public let name: String
  public let provider: SocialType
  public let token: AuthTokens
  public let isNewUser: Bool
  public let userTag: String
  public let status: String

  public init(
    name: String,
    isNewUser: Bool,
    provider: SocialType,
    token: AuthTokens,
    userTag: String = "",
    status: String = ""
  ) {
    self.name = name
    self.isNewUser = isNewUser
    self.provider = provider
    self.token = token
    self.userTag = userTag
    self.status = status
  }
}
