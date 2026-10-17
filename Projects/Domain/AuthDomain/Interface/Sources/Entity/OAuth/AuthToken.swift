//
//  AuthToken.swift
//  AuthDomainInterface
//
//  Created by Picke on 12/29/25.
//

import Foundation

public struct AuthTokens: Equatable, Hashable {
  public let accessToken: String
  public let refreshToken: String
  public let oauthRefreshToken: String?

  public init(
    accessToken: String,
    refreshToken: String,
    oauthRefreshToken: String? = nil
  ) {
    self.accessToken = accessToken
    self.refreshToken = refreshToken
    self.oauthRefreshToken = oauthRefreshToken
  }
}
