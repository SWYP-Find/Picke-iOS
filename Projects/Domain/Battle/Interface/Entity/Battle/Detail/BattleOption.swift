//
//  BattleOption.swift
//  Entity
//

import Foundation
import HomeDomainInterface

public struct BattleOption: Equatable, Identifiable, Hashable {
  public let optionId: Int
  public let label: String
  public let title: String
  public let stance: String
  public let representative: String
  public let imageUrl: String
  public let tags: [BattleTag]

  public var id: Int { optionId }

  public init(
    optionId: Int,
    label: String,
    title: String,
    stance: String,
    representative: String,
    imageUrl: String,
    tags: [BattleTag]
  ) {
    self.optionId = optionId
    self.label = label
    self.title = title
    self.stance = stance
    self.representative = representative
    self.imageUrl = imageUrl
    self.tags = tags
  }
}
