//
//  CreditHistoryQueryRequest.swift
//  Service
//

import Foundation

public struct CreditHistoryQueryRequest: Encodable, Sendable {
  public let offset: Int?
  public let size: Int?

  public init(
    offset: Int? = nil,
    size: Int? = nil
  ) {
    self.offset = offset
    self.size = size
  }
}
