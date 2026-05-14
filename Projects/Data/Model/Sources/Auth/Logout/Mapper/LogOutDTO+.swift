//
//  LogOutDTO+.swift
//  Model
//
//  Created by Wonji Suh on 5/14/26.
//

import Entity
import Foundation

public extension LogOutDTO {
  func toDomain() -> AuthExitEntity {
    AuthExitEntity(
      code: code,
      message: message,
      detail: detail
    )
  }
}
