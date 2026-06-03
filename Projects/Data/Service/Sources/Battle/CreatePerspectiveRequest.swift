//
//  CreatePerspectiveRequest.swift
//  Service
//
//  Created by Wonji Suh  on 5/24/26.
//

import Foundation

public struct CreatePerspectiveRequest: Encodable {
  public let content: String
  public let optionId: Int
  
  public init(
    content: String,
    optionId: Int
  ) {
    self.content = content
    self.optionId = optionId
  }
}
