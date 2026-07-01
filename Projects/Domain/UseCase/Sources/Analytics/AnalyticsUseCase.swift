//
//  AnalyticsUseCase.swift
//  UseCase
//
//  Mixpanel 트래킹 UseCase. 이벤트 정의는 AnalyticsEvent.swift / Events/ 참고.
//  이벤트를 쪼개지 않고 하나의 카테고리 + 속성값으로 구분(무료 플랜 한도 절약).
//  설계: docs/analytics-mixpanel-design.md
//

import Foundation

import ComposableArchitecture
import Entity
import LogMacro
import Mixpanel
import MixpanelSessionReplay

// MARK: - UseCase

public struct AnalyticsUseCase: Sendable {
  /// 앱 시작 시 공통 슈퍼 프로퍼티(os_type/app_version/build) 등록.
  public var registerBaseProperties: @Sendable () -> Void
  /// 로그인 성공 직후 유저 고유 ID 연결 + 로그인 슈퍼/유저 프로퍼티 설정.
  public var identify: @Sendable (_ userID: String, _ method: String?) -> Void
  /// 핵심 퍼널 이벤트 트래킹.
  public var track: @Sendable (_ event: AnalyticsEvent) -> Void
  /// 로그아웃/탈퇴 시 계정 분리(reset) + 공통 프로퍼티 재등록.
  public var reset: @Sendable () -> Void

  public init(
    registerBaseProperties: @escaping @Sendable () -> Void,
    identify: @escaping @Sendable (_ userID: String, _ method: String?) -> Void,
    track: @escaping @Sendable (_ event: AnalyticsEvent) -> Void,
    reset: @escaping @Sendable () -> Void
  ) {
    self.registerBaseProperties = registerBaseProperties
    self.identify = identify
    self.track = track
    self.reset = reset
  }
}

extension AnalyticsUseCase: DependencyKey {
  /// 모든 이벤트에 자동 첨부되는 공통 슈퍼 프로퍼티(플랫폼/버전). is_logged_in 은 identify/reset 이 관리.
  public static func baseSuperProperties() -> Properties {
    let info = Bundle.main.infoDictionary
    return [
      "os_type": "ios",
      "app_version": (info?["CFBundleShortVersionString"] as? String) ?? "",
      "build": (info?["CFBundleVersion"] as? String) ?? "",
    ]
  }

  public static let liveValue = AnalyticsUseCase(
    registerBaseProperties: {
      Mixpanel.mainInstance().registerSuperProperties(baseSuperProperties())
    },
    identify: { userID, method in
      guard !userID.isEmpty else { return }

      let mixpanel = Mixpanel.mainInstance()
      mixpanel.identify(distinctId: userID)
      MPSessionReplay.getInstance()?.identify(distinctId: userID)

      // 로그인 컨텍스트를 슈퍼 프로퍼티로 등록 → 이후 모든 이벤트에 자동 첨부.
      var superProps: Properties = ["is_logged_in": true]
      if let method, !method.isEmpty {
        superProps["login_provider"] = method
      }
      mixpanel.registerSuperProperties(superProps)

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
    },
    reset: {
      let mixpanel = Mixpanel.mainInstance()
      mixpanel.reset() // 슈퍼 프로퍼티 포함 전체 초기화 → 계정 분리.
      mixpanel.registerSuperProperties(baseSuperProperties()) // 공통 프로퍼티 재등록(is_logged_in 미포함 = 로그아웃).
    }
  )

  public static let testValue = AnalyticsUseCase(
    registerBaseProperties: {},
    identify: { _, _ in },
    track: { _ in },
    reset: {}
  )
  public static let previewValue = testValue

  private static func eventName(_ event: AnalyticsEvent) -> String {
    switch event {
    case .signUp: "sign_up"
    case .battleStep: "battle_step"
    case .reportAction: "report_action"
    case .communityAction: "community_action"
    case .adRevenue: "ad_revenue"
    case .onboardingStep: "onboarding_step"
    case .pointAction: "point_action"
    case .notificationAction: "notification_action"
    case .shareAction: "share_action"
    case .screenView: "screen_view"
    case .contentAction: "content_action"
    case .uiAction: "ui_action"
    case .playbackAction: "playback_action"
    case .engagementAction: "engagement_action"
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

    case let .onboardingStep(step, method):
      var properties: Properties = ["step": step.rawValue]
      if let method, !method.isEmpty {
        properties["method"] = method
      }
      return properties

    case let .pointAction(data):
      var properties: Properties = [
        "type": data.type.rawValue,
        "amount": data.amount,
      ]
      if let balance = data.balance {
        properties["balance"] = balance
      }
      return properties

    case let .notificationAction(data):
      var properties: Properties = ["action": data.action.rawValue]
      if let count = data.unreadCount {
        properties["unread_count"] = count
      }
      return properties

    case let .shareAction(data):
      var properties: Properties = ["target": data.target.rawValue]
      if let channel = data.channel {
        properties["channel"] = channel
      }
      return properties

    case let .screenView(screen, referrer):
      var properties: Properties = ["screen": screen.rawValue]
      if let referrer, !referrer.isEmpty {
        properties["referrer"] = referrer
      }
      return properties

    case let .contentAction(data):
      var properties: Properties = ["action": data.action.rawValue]
      if let contentID = data.contentID {
        properties["content_id"] = contentID
      }
      if let section = data.section {
        properties["section"] = section
      }
      return properties

    case let .uiAction(action, screen):
      return ["action": action.rawValue, "screen": screen.rawValue]

    case let .playbackAction(action, contentID):
      return ["action": action, "content_id": contentID]

    case let .engagementAction(action, targetID):
      return ["action": action, "target_id": targetID]
    }
  }
}

public extension DependencyValues {
  var analyticsUseCase: AnalyticsUseCase {
    get { self[AnalyticsUseCase.self] }
    set { self[AnalyticsUseCase.self] = newValue }
  }
}
