//
//  WithdrawRequest.swift
//  APIEndpoint
//
//  Created by Picke on 10/11/26.
//

import Foundation

public struct WithdrawRequest: Encodable, Sendable {
  public let reason: String

  public init(reason: String) {
    self.reason = reason
  }
}
