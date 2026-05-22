//
//  BattleDetail.swift
//  Entity
//
//  `GET /api/v1/battles/{battleId}` 응답 도메인 모델.
//

import Foundation

public struct BattleDetail: Equatable, Identifiable {
  public let battleInfo: BattleInfo
  public let description: String
  public let shareUrl: String
  public let userVoteStatus: UserVoteStatus
  public let currentStep: BattleStep
  public let categoryTags: [BattleTag]
  public let philosopherTags: [BattleTag]
  public let valueTags: [BattleTag]

  public var id: Int { battleInfo.battleId }

  public init(
    battleInfo: BattleInfo,
    description: String,
    shareUrl: String,
    userVoteStatus: UserVoteStatus,
    currentStep: BattleStep,
    categoryTags: [BattleTag],
    philosopherTags: [BattleTag],
    valueTags: [BattleTag]
  ) {
    self.battleInfo = battleInfo
    self.description = description
    self.shareUrl = shareUrl
    self.userVoteStatus = userVoteStatus
    self.currentStep = currentStep
    self.categoryTags = categoryTags
    self.philosopherTags = philosopherTags
    self.valueTags = valueTags
  }
}

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

public enum UserVoteStatus: String, Equatable, Hashable, CaseIterable {
  case none = "NONE"
  case pro = "PRO"
  case con = "CON"
  case unknown

  public init(rawValue: String) {
    self = UserVoteStatus.allCases.first { $0.rawValue == rawValue } ?? .unknown
  }
}

public enum BattleStep: String, Equatable, Hashable, CaseIterable {
  case none = "NONE"
  case preVote = "PRE_VOTE"
  case listening = "LISTENING"
  case postVote = "POST_VOTE"
  case finished = "FINISHED"
  case unknown

  public init(rawValue: String) {
    self = BattleStep.allCases.first { $0.rawValue == rawValue } ?? .unknown
  }
}
