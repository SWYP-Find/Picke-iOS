//
//  BattleProposalRequest.swift
//  Service
//

import Foundation

public struct BattleProposalRequest: Encodable, Sendable {
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

  private enum CodingKeys: String, CodingKey {
    case category
    case topic
    case positionA
    case positionB
    case description
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(category, forKey: .category)
    try container.encode(topic, forKey: .topic)
    try container.encode(positionA, forKey: .positionA)
    try container.encode(positionB, forKey: .positionB)
    try container.encode(description, forKey: .description)
  }
}
