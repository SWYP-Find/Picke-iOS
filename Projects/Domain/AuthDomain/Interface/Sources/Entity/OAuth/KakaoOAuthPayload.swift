//
//  KakaoOAuthPayload.swift
//  Domain
//
//  Created by Assistant on 12/4/25.
//

import Foundation

/// Kakao OAuth 콜백에서 받은 백엔드 로그인 결과
public struct KakaoOAuthPayload {
  public let idToken: String
  public let accessToken: String
  public let refreshToken: String?
  public let authorizationCode: String?
  public let displayName: String?
  public let codeVerifier: String?
  public let redirectUri: String?
  public let userTag: String?
  public let status: String?
  public let isNewUser: Bool

  public init(
    idToken: String,
    accessToken: String,
    refreshToken: String? = nil,
    authorizationCode: String? = nil,
    displayName: String? = nil,
    codeVerifier: String? = nil,
    redirectUri: String? = nil,
    userTag: String? = nil,
    status: String? = nil,
    isNewUser: Bool = false
  ) {
    self.idToken = idToken
    self.accessToken = accessToken
    self.refreshToken = refreshToken
    self.authorizationCode = authorizationCode
    self.displayName = displayName
    self.codeVerifier = codeVerifier
    self.redirectUri = redirectUri
    self.userTag = userTag
    self.status = status
    self.isNewUser = isNewUser
  }
}
