//
//  OAuthRequest.swift
//  Service
//
//  Created by Wonji Suh on 5/14/26.
//

import Foundation

/// `/api/v1/auth/login/{provider}` 요청 바디.
/// - `idToken`: Apple 로그인에서만 채워서 보낸다 (JSON key: `identityToken`).
/// - `redirectUri`: Apple 은 nil 로 보낸다 (서버에서 redirect 사용 X).
public struct OAuthLoginRequest: Encodable, Sendable {
  public let authorizationCode: String
  public let redirectUri: String?
  public let idToken: String?

  enum CodingKeys: String, CodingKey {
    case authorizationCode
    case redirectUri
    case idToken = "identityToken"
  }

  public init(
    authorizationCode: String,
    redirectUri: String?,
    idToken: String? = nil
  ) {
    self.authorizationCode = authorizationCode
    self.redirectUri = redirectUri
    self.idToken = idToken
  }
}
