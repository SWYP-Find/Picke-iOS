//
//  TokenDTO+.swift
//  AuthDomain
//
//  Created by Picke on 5/14/26.
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
