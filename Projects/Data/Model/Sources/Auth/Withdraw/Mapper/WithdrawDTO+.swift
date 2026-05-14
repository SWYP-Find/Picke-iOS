//
//  WithdrawDTO+.swift
//  Model
//
//  Created by Wonji Suh on 5/14/26.
//

import Entity
import Foundation

public extension WithdrawDTO {
  func toDomain(isSuccess: Bool) -> WithdrawEntity {
    WithdrawEntity(
      isSuccess: isSuccess,
      code: code,
      message: message,
      detail: detail
    )
  }
}
