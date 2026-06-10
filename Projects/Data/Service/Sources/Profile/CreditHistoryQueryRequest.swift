//
//  CreditHistoryQueryRequest.swift
//  Service
//
//  GET /api/v1/me/credits/history 쿼리 파라미터.
//

import Foundation

public struct CreditHistoryQueryRequest: Encodable {
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
