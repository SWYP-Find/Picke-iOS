//
//  AnalyticsUseCase+Live.swift
//  PickeAnalytics
//

import Foundation

import PickeAnalyticsInterface
import ComposableArchitecture
import LogMacro
import Mixpanel
import MixpanelSessionReplay
@preconcurrency import Sentry

// MARK: - Live

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

      // Sentry 이슈에도 같은 유저를 붙인다 — 크래시가 누구에게 터졌는지 Mixpanel 과 동일 ID 로 대조된다.
      let user = User(userId: userID)
      if let method, !method.isEmpty {
        user.data = ["login_provider": method]
      }
      SentrySDK.setUser(user)
    },
    track: { event in
      let mixpanel = Mixpanel.mainInstance()
      let name = eventName(event)
      let properties = eventProperties(event)
      #logDebug("Mixpanel track", ["event": name, "properties": String(describing: properties)])
      mixpanel.track(event: name, properties: properties)
      enrichPeopleProfile(mixpanel, event: event)
      monitorInSentry(name: name, properties: properties, event: event)
    },
    reset: {
      let mixpanel = Mixpanel.mainInstance()
      mixpanel.reset() // 슈퍼 프로퍼티 포함 전체 초기화 → 계정 분리.
      mixpanel.registerSuperProperties(baseSuperProperties()) // 공통 프로퍼티 재등록(is_logged_in 미포함 = 로그아웃).
      SentrySDK.setUser(nil) // 다음 이슈가 이전 계정에 붙지 않도록 함께 끊는다.
    }
  )

  /// 트래킹한 유저 액션을 Sentry 에도 남긴다. 셋 다 목적이 다르다.
  /// - breadcrumb: 크래시 직전 행동 흐름. Mixpanel 을 따로 열지 않고 이슈 화면에서 바로 읽는다.
  /// - `user.action.count`: 액션 종류별 발생량. 배포 후 특정 화면 진입이 끊기면 여기서 먼저 보인다.
  /// - `ad.click.count`: 광고 클릭만 따로 집계. 지면·형태별로 나눠 본다.
  private static func monitorInSentry(name: String, properties: Properties, event: AnalyticsEvent) {
    let attributes = properties.compactMapValues { $0 as? String }

    let breadcrumb = Breadcrumb(level: .info, category: "user.action")
    breadcrumb.message = name
    breadcrumb.data = properties.mapValues { $0 as Any }
    SentrySDK.addBreadcrumb(breadcrumb)

    var metricAttributes: [String: any SentryAttributeValue] = ["event": name]
    for (key, value) in attributes {
      metricAttributes[key] = value
    }
    SentrySDK.metrics.count(key: "user.action.count", value: 1, attributes: metricAttributes)

    // 광고 클릭은 매출과 직결돼 별도 카운터 + 로그로 남긴다(로그는 검색/필터 대상).
    guard case let .adClick(data) = event else { return }
    SentrySDK.metrics.count(
      key: "ad.click.count",
      value: 1,
      attributes: [
        "placement": data.placement.rawValue,
        "format": data.format.rawValue,
      ]
    )
    SentrySDK.logger.info("ad_click", attributes: metricAttributes)
  }

  /// Mixpanel 유저 프로필 누적. 이벤트만으론 "이 유저가 광고를 얼마나 누르는 사람인지" 를
  /// 코호트로 못 뽑아서, 사람 단위 지표를 함께 쌓는다.
  private static func enrichPeopleProfile(_ mixpanel: MixpanelInstance, event: AnalyticsEvent) {
    switch event {
    case let .adClick(data):
      mixpanel.people.increment(property: "ad_click_count", by: 1)
      mixpanel.people.set(properties: [
        "last_ad_click_at": Date(),
        "last_ad_placement": data.placement.rawValue,
      ])

    case let .adRevenue(placement):
      mixpanel.people.increment(property: "ad_reward_count", by: 1)
      mixpanel.people.set(properties: ["last_ad_reward_placement": placement.rawValue])

    default:
      break
    }
  }

  private static func eventName(_ event: AnalyticsEvent) -> String {
    switch event {
    case .signUp: "sign_up"
    case .battleStep: "battle_step"
    case .reportAction: "report_action"
    case .communityAction: "community_action"
    case .adRevenue: "ad_revenue"
    case .adClick: "ad_click"
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
      return ["method": method.rawValue]

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
      return ["placement": placement.rawValue]

    case let .adClick(data):
      var properties: Properties = [
        "placement": data.placement.rawValue,
        "format": data.format.rawValue,
      ]
      if let unit = data.unit {
        properties["unit"] = unit
      }
      return properties

    case let .onboardingStep(step, provider):
      var properties: Properties = ["step": step.rawValue]
      if let provider {
        properties["method"] = provider.rawValue
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
      if let referrer {
        properties["referrer"] = referrer.rawValue
      }
      return properties

    case let .contentAction(data):
      var properties: Properties = ["action": data.action.rawValue]
      if let contentID = data.contentID {
        properties["content_id"] = contentID
      }
      if let section = data.section {
        properties["section"] = section.rawValue
      }
      return properties

    case let .uiAction(action, screen):
      return ["action": action.rawValue, "screen": screen.rawValue]

    case let .playbackAction(action, contentID):
      return ["action": action.rawValue, "content_id": contentID]

    case let .engagementAction(action, targetID):
      return ["action": action.rawValue, "target_id": targetID]
    }
  }
}
