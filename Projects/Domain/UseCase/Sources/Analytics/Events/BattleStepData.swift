//
//  BattleStepData.swift
//  UseCase
//

import Foundation

public enum BattleStep: String, Sendable {
  case preVote = "pre_vote"
  case audioEnd = "audio_end"
  case postVote = "post_vote"
}

public struct BattleStepData: Sendable {
  public let stepName: BattleStep
  public let contentID: String
  /// 선택지(좌/우 등). 없으면 미전송.
  public let choice: String?
  /// 사전→사후 투표 변경 여부. post_vote 에서만 유의미.
  public let isChanged: Bool?

  public init(
    stepName: BattleStep,
    contentID: String,
    choice: String? = nil,
    isChanged: Bool? = nil
  ) {
    self.stepName = stepName
    self.contentID = contentID
    self.choice = choice
    self.isChanged = isChanged
  }
}
