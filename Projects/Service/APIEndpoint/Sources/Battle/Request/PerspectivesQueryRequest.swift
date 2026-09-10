//
//  PerspectivesQueryRequest.swift
//  Service
//

import Foundation

public struct PerspectivesQueryRequest: Encodable, Sendable {
  public let cursor: String?
  public let size: Int?
  public let optionId: Int?
  public let sort: String?

  public init(
    cursor: String? = nil,
    size: Int? = nil,
    optionId: Int? = nil,
    sort: String? = nil
  ) {
    self.cursor = cursor
    self.size = size
    self.optionId = optionId
    self.sort = sort
  }
}
