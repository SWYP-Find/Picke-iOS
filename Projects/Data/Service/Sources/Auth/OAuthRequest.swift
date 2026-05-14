//
//  OAuthRequest.swift
//  Service
//
//  Created by Wonji Suh on 5/14/26.
//

import Foundation

/// `/api/v1/auth/login/{provider}` 요청 바디
public struct OAuthLoginRequest: Encodable {
  public let authorizationCode: String
  public let redirectUri: String

  public init(
    authorizationCode: String,
    redirectUri: String
  ) {
    self.authorizationCode = authorizationCode
    self.redirectUri = redirectUri
  }
}
