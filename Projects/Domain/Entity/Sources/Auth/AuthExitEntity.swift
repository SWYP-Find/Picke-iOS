//
//  AuthExitEntity.swift
//  Entity
//
//  Created by Wonji Suh on 5/14/26.
//

import Foundation

public struct AuthExitEntity: Equatable {
  public let loggedOut: Bool
  public let code: String?
  public let message: String?
  public let detail: String?

  public init(
    loggedOut: Bool = false,
    code: String? = nil,
    message: String? = nil,
    detail: String? = nil
  ) {
    self.loggedOut = loggedOut
    self.code = code
    self.message = message
    self.detail = detail
  }
}
