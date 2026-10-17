//
//  PerspectiveCommentsQueryRequest.swift
//  APIEndpoint
//
//  Created by Picke on 10/11/26.
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
