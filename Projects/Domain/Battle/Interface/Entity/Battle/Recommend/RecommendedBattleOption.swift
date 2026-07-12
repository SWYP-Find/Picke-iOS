//
//  RecommendedBattleOption.swift
//  Entity
//

import Foundation

public struct RecommendedBattleOption: Equatable, Hashable, Identifiable {
  public let optionId: Int
  public let title: String
  public let stance: String
  public let representative: String
  public let imageUrl: String?

  public var id: Int { optionId }

  public init(
    optionId: Int,
    title: String,
    stance: String,
    representative: String,
    imageUrl: String?
  ) {
    self.optionId = optionId
    self.title = title
    self.stance = stance
    self.representative = representative
    self.imageUrl = imageUrl
  }
}
