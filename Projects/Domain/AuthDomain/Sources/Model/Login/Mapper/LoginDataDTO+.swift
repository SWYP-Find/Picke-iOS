//
//  LoginDataDTO+.swift
//  Model
//
//  Created by Wonji Suh on 5/14/26.
//

import AuthDomainInterface
import Foundation

public extension LoginDataDTO {
  func toDomain(provider: SocialType) -> LoginEntity {
    let token = AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken
    )
    return LoginEntity(
      name: "",
      isNewUser: newUser,
      provider: provider,
      token: token,
      userTag: userTag,
      status: status
    )
  }
}
