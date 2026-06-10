//
//  BattleVoteStatsOption.swift
//  Entity
//

import Foundation

public struct BattleVoteStatsOption: Equatable, Identifiable, Hashable {
  public let optionId: Int
  public let label: String?
  public let title: String
  public let isCorrect: Bool
  public let voteCount: Int
  public let ratio: Double
  public let stance: String
  public let imageUrl: String?

  public var id: Int { optionId }

  public init(
    optionId: Int,
    label: String?,
    title: String,
    isCorrect: Bool,
    voteCount: Int,
    ratio: Double,
    stance: String,
    imageUrl: String?
  ) {
    self.optionId = optionId
    self.label = label
    self.title = title
    self.isCorrect = isCorrect
    self.voteCount = voteCount
    self.ratio = ratio
    self.stance = stance
    self.imageUrl = imageUrl
  }
}
