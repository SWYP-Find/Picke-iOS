//
//  PerspectiveCommentsQueryRequest.swift
//  APIEndpoint
//

import Foundation

public struct PerspectiveCommentsQueryRequest: Encodable, Sendable {
  public let cursor: String?
  public let size: Int?

  public init(cursor: String?, size: Int?) {
    self.cursor = cursor
    self.size = size
  }
}
