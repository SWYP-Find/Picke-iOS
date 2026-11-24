//
//  PreVoteOption.swift
//  BattleDomainInterface
//
//  Created by Picke on 10/11/26.
//

import Foundation

public struct PreVoteOption: Equatable, Identifiable, Hashable {
  public let optionId: Int
  public let representative: String
  public let imageURL: String
  public let stance: String

  public var id: Int { optionId }

  public init(
    optionId: Int,
    representative: String,
    imageURL: String,
    stance: String
  ) {
    self.optionId = optionId
    self.representative = representative
    self.imageURL = imageURL
    self.stance = stance
  }
}
