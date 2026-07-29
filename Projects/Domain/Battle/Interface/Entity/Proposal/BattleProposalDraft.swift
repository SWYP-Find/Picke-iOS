//
//  BattleProposalDraft.swift
//  Entity
//

import Foundation

public struct BattleProposalDraft: Equatable {
  public let category: String
  public let topic: String
  public let positionA: String
  public let positionB: String
  public let description: String

  public init(
    category: String,
    topic: String,
    positionA: String,
    positionB: String,
    description: String
  ) {
    self.category = category
    self.topic = topic
    self.positionA = positionA
    self.positionB = positionB
    self.description = description
  }
}
