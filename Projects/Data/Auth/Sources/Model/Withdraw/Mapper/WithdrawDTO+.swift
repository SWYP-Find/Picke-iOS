//
//  WithdrawDTO+.swift
//  Model
//
//  Created by Wonji Suh on 5/14/26.
//

import AuthDomainInterface
import Foundation

public extension WithdrawDTO {
  func toDomain(isSuccess: Bool) -> WithdrawEntity {
    let withdrawn = data?.withdrawn ?? isSuccess

    return WithdrawEntity(
      isSuccess: withdrawn,
      withdrawn: withdrawn,
      code: error?.code,
      message: error?.message
    )
  }
}
