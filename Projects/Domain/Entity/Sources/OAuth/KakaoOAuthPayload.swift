//
//  KakaoOAuthPayload.swift
//  Domain
//
//  Created by Assistant on 12/4/25.
//

import Foundation

public struct KakaoOAuthPayload {
  public let idToken: String
  public let accessToken: String
  public let refreshToken: String?
  public let authorizationCode: String?
  public let displayName: String?
  public let codeVerifier: String?
  public let redirectUri: String?
  
  public init(
    idToken: String,
    accessToken: String,
    refreshToken: String?,
    authorizationCode: String?,
    displayName: String?,
    codeVerifier: String?,
    redirectUri: String?
  ) {
    self.idToken = idToken
    self.accessToken = accessToken
    self.refreshToken = refreshToken
    self.authorizationCode = authorizationCode
    self.displayName = displayName
    self.codeVerifier = codeVerifier
    self.redirectUri = redirectUri
  }
}
