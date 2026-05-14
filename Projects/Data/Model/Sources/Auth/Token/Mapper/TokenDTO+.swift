//
//  TokenDTO+.swift
//  Model
//
//  Created by Wonji Suh on 5/14/26.
//

import Entity
import Foundation

public extension TokenDTO {
  func toDomain() -> AuthTokens {
    AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken
    )
  }
}
