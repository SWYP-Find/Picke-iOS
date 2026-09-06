//
//  TokenDTO+.swift
//  AuthDomain
//
//  Created by Wonji Suh on 5/14/26.
//

import AuthDomainInterface
import Foundation

public extension TokenDTO {
  func toDomain() -> AuthTokens {
    AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken
    )
  }
}
