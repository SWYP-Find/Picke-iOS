//
//  GoogleOAuthPayload.swift
//  Entity
//
//  Created by Wonji Suh  on 12/29/25.
//

import Foundation

/// Google OAuth 콜백에서 받은 백엔드 로그인 결과
public struct GoogleOAuthPayload {
  public let idToken: String
  public let accessToken: String?
  public let refreshToken: String?
  public let authorizationCode: String?
  public let displayName: String?
  public let userTag: String?
  public let status: String?
  public let isNewUser: Bool
  public let redirectUri: String?

  public init(
    idToken: String,
    accessToken: String?,
    refreshToken: String? = nil,
    authorizationCode: String? = nil,
    displayName: String? = nil,
    userTag: String? = nil,
    status: String? = nil,
    isNewUser: Bool = false,
    redirectUri: String? = nil
  ) {
    self.idToken = idToken
    self.accessToken = accessToken
    self.refreshToken = refreshToken
    self.authorizationCode = authorizationCode
    self.displayName = displayName
    self.userTag = userTag
    self.status = status
    self.isNewUser = isNewUser
    self.redirectUri = redirectUri
  }
}
