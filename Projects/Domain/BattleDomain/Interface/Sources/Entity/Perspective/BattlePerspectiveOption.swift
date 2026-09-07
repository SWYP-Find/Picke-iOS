//
//  BattlePerspectiveOption.swift
//  BattleDomainInterface
//

import Foundation

public struct BattlePerspectiveOption: Equatable, Hashable, Identifiable {
  public let optionId: Int
  public let label: String?
  public let title: String
  public let stance: String

  public var id: Int { optionId }

  public init(
    optionId: Int,
    label: String?,
    title: String,
    stance: String
  ) {
    self.optionId = optionId
    self.label = label
    self.title = title
    self.stance = stance
  }
}
