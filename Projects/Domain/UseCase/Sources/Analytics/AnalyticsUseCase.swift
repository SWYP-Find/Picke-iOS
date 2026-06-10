//
//  AnalyticsUseCase.swift
//  UseCase
//
//  Mixpanel 트래킹 — PICKé 핵심 이벤트 명세서 기준.
//  이벤트를 쪼개지 않고 하나의 카테고리 + 속성값으로 구분(무료 플랜 한도 절약).
//

import Foundation

import ComposableArchitecture
import Entity
import LogMacro
import Mixpanel
import MixpanelSessionReplay

// MARK: - 이벤트 정의 (명세서)

public enum AnalyticsEvent: Sendable {
  /// 소셜 가입 완료 및 메인 진입 시.
  case signUp(method: String)
  /// 배틀 각 단계 완료 시 (pre_vote / audio_end / post_vote).
  case battleStep(BattleStepData)
  /// 리포트 조회/공유 클릭 시.
  case reportAction(ReportActionData)
  /// 댓글 등록 성공 시.
  case communityAction(CommunityActionData)
  /// 보상형 광고 시청 완료 시.
  case adRevenue(placement: String)
}

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

public struct CommunityActionData: Sendable {
  public let contentID: String
  public let commentLength: Int

  public init(contentID: String, commentLength: Int) {
    self.contentID = contentID
    self.commentLength = commentLength
  }
}

// MARK: - UseCase

public struct AnalyticsUseCase: Sendable {
  /// 로그인 성공 직후 유저 고유 ID 를 Mixpanel 에 연결.
  public var identify: @Sendable (_ userID: String, _ method: String?) -> Void
  /// 핵심 퍼널 이벤트 트래킹.
  public var track: @Sendable (_ event: AnalyticsEvent) -> Void

  public init(
    identify: @escaping @Sendable (_ userID: String, _ method: String?) -> Void,
    track: @escaping @Sendable (_ event: AnalyticsEvent) -> Void
  ) {
    self.identify = identify
    self.track = track
  }
}

extension AnalyticsUseCase: DependencyKey {
  public static let liveValue = AnalyticsUseCase(
    identify: { userID, method in
      guard !userID.isEmpty else { return }

      let mixpanel = Mixpanel.mainInstance()
      mixpanel.identify(distinctId: userID)
      MPSessionReplay.getInstance()?.identify(distinctId: userID)

      var properties: Properties = [:]
      if let method, !method.isEmpty {
        properties["provider"] = method
      }
      if !properties.isEmpty {
        mixpanel.people.set(properties: properties)
      }
    },
    track: { event in
      let mixpanel = Mixpanel.mainInstance()
      let name = eventName(event)
      let properties = eventProperties(event)
      #logDebug("Mixpanel track", ["event": name, "properties": String(describing: properties)])
      mixpanel.track(event: name, properties: properties)
    }
  )

  public static let testValue = AnalyticsUseCase(identify: { _, _ in }, track: { _ in })
  public static let previewValue = testValue

  private static func eventName(_ event: AnalyticsEvent) -> String {
    switch event {
    case .signUp: "sign_up"
    case .battleStep: "battle_step"
    case .reportAction: "report_action"
    case .communityAction: "community_action"
    case .adRevenue: "ad_revenue"
    }
  }

  private static func eventProperties(_ event: AnalyticsEvent) -> Properties {
    switch event {
    case let .signUp(method):
      return ["method": method]

    case let .battleStep(data):
      var properties: Properties = [
        "step_name": data.stepName.rawValue,
        "content_id": data.contentID,
      ]
      if let choice = data.choice {
        properties["choice"] = choice
      }
      if let isChanged = data.isChanged {
        properties["is_changed"] = isChanged
      }
      return properties

    case let .reportAction(data):
      var properties: Properties = ["action_type": data.actionType.rawValue]
      if let topIndicator = data.topIndicator {
        properties["top_indicator"] = topIndicator
      }
      return properties

    case let .communityAction(data):
      return [
        "content_id": data.contentID,
        "comment_length": data.commentLength,
      ]

    case let .adRevenue(placement):
      return ["placement": placement]
    }
  }
}

public extension DependencyValues {
  var analyticsUseCase: AnalyticsUseCase {
    get { self[AnalyticsUseCase.self] }
    set { self[AnalyticsUseCase.self] = newValue }
  }
}
