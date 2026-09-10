//
//  LogOutDTO+.swift
//  AuthDomain
//
//  Created by Wonji Suh on 5/14/26.
//

import AuthDomainInterface
import Foundation

public extension LogOutDTO {
  func toDomain() -> AuthExitEntity {
    AuthExitEntity(
      loggedOut: data?.loggedOut ?? false,
      code: error?.code,
      message: error?.message
    )
  }
}
