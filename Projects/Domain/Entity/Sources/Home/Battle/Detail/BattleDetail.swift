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
