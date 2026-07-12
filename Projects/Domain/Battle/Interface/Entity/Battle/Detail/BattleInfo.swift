//
//  BattleInfo.swift
//  Entity
//

import Foundation
import CommonDomainInterface

public struct BattleInfo: Equatable, Identifiable {
  public let battleId: Int
  public let title: String
  public let summary: String
  public let thumbnailUrl: String
  public let viewCount: Int
  public let participantsCount: Int
  public let audioDuration: Int
  public let tags: [BattleTag]
  public let options: [BattleOption]

  public var id: Int { battleId }

  public init(
    battleId: Int,
    title: String,
    summary: String,
    thumbnailUrl: String,
    viewCount: Int,
    participantsCount: Int,
    audioDuration: Int,
    tags: [BattleTag],
    options: [BattleOption]
  ) {
    self.battleId = battleId
    self.title = title
    self.summary = summary
    self.thumbnailUrl = thumbnailUrl
    self.viewCount = viewCount
    self.participantsCount = participantsCount
    self.audioDuration = audioDuration
    self.tags = tags
    self.options = options
  }
}
