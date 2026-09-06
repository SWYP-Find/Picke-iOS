//
//  WithdrawDTO.swift
//  Model
//
//  Created by Wonji Suh on 5/14/26.
//

import Foundation
import Model

public struct WithdrawDataDTO: Decodable, Equatable {
  public let withdrawn: Bool

  public init(withdrawn: Bool) {
    self.withdrawn = withdrawn
  }
}

public struct WithdrawDTO: Decodable {
  public let statusCode: Int
  public let data: WithdrawDataDTO?
  public let error: APIErrorDTO?

  public init(
    statusCode: Int,
    data: WithdrawDataDTO? = nil,
    error: APIErrorDTO? = nil
  ) {
    self.statusCode = statusCode
    self.data = data
    self.error = error
  }
}
