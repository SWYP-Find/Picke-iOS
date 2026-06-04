//
//  CreatePerspectiveRequest.swift
//  Service
//
//  Created by Wonji Suh  on 5/24/26.
//

import Foundation

public struct CreatePerspectiveRequest: Encodable {
  public let content: String
  public let optionId: Int?

  public init(content: String, optionId: Int? = nil) {
    self.content = content
    self.optionId = optionId
  }

  private enum CodingKeys: String, CodingKey {
    case content
    case optionId
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(content, forKey: .content)
    try container.encodeIfPresent(optionId, forKey: .optionId)
  }
}
