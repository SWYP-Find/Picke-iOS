//
//  RecommendedBattleTag.swift
//  Entity
//

import Foundation

public struct RecommendedBattleTag: Equatable, Hashable, Identifiable {
  public let tagId: Int
  public let name: String

  public var id: Int { tagId }

  public init(tagId: Int, name: String) {
    self.tagId = tagId
    self.name = name
  }
}
