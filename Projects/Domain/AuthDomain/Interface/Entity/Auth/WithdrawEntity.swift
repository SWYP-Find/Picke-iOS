//
//  WithdrawEntity.swift
//  Entity
//
//  Created by Wonji Suh on 5/14/26.
//

import Foundation

public struct WithdrawEntity: Equatable {
  public let isSuccess: Bool
  public let withdrawn: Bool
  public let code: String?
  public let message: String?
  public let detail: String?

  public init(
    isSuccess: Bool,
    withdrawn: Bool? = nil,
    code: String? = nil,
    message: String? = nil,
    detail: String? = nil
  ) {
    self.isSuccess = isSuccess
    self.withdrawn = withdrawn ?? isSuccess
    self.code = code
    self.message = message
    self.detail = detail
  }
}
