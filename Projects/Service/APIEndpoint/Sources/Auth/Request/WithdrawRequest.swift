//
//  WithdrawRequest.swift
//  APIEndpoint
//

import Foundation

public struct WithdrawRequest: Encodable, Sendable {
  public let reason: String

  public init(reason: String) {
    self.reason = reason
  }
}
