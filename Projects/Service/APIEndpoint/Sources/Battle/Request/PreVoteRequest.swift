//
//  PreVoteRequest.swift
//  Service
//
//  Created by Wonji Suh  on 5/21/26.
//

import Foundation

public struct PreVoteRequest: Encodable, Sendable {
  public let optionId: Int
  
  public init(optionId: Int) {
    self.optionId = optionId
  }
}
