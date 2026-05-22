//
//  PerspectivesQueryRequest.swift
//  Service
//
//  GET /api/v1/battles/{battleId}/perspectives 쿼리 파라미터.
//

import Foundation

public struct PerspectivesQueryRequest: Encodable {
  public let cursor: String?
  public let size: Int?
  public let optionLabel: String?
  public let sort: String?

  public init(
    cursor: String? = nil,
    size: Int? = nil,
    optionLabel: String? = nil,
    sort: String? = nil
  ) {
    self.cursor = cursor
    self.size = size
    self.optionLabel = optionLabel
    self.sort = sort
  }
}
