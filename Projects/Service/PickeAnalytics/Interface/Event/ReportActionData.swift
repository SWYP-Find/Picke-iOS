//
//  ReportActionData.swift
//  UseCase
//

import Foundation

public enum ReportActionType: String, Sendable {
  case view
  case share
}

public struct ReportActionData: Sendable {
  public let actionType: ReportActionType
  /// 대표 지표(최상위 철학자 유형 등). 없으면 미전송.
  public let topIndicator: String?

  public init(actionType: ReportActionType, topIndicator: String? = nil) {
    self.actionType = actionType
    self.topIndicator = topIndicator
  }
}
