//
//  AnalyticsUseCase.swift
//  UseCase
//
//  Mixpanel 이벤트 트래킹 — 타입 안전한 이벤트 + 공통 유저 프로퍼티.
//  (TimeSpot-iOS AnalyticsUseCase 패턴을 Picke 도메인에 맞춰 적용)
//

import Foundation

import ComposableArchitecture
import Entity
import LogMacro
import Mixpanel
import MixpanelSessionReplay

// MARK: - 이벤트 정의

public enum AnalyticsEvent: Sendable {
  case auth(AuthEventType, AuthEventData)
  case battle(BattleEventType, BattleEventData)
  case session(SessionEventType, SessionEventData)
}

public enum AuthEventType: String, Sendable {
  case loginSucceeded = "login_succeeded"
  case loginFailed = "login_failed"
  case signupSucceeded = "signup_succeeded"
  case signupFailed = "signup_failed"
}

public struct AuthEventData: Sendable {
  public let username: String?
  public let userTag: String?
  public let socialType: String?
  public let isNewUser: Bool?
  public let errorDescription: String?

  public init(
    username: String? = nil,
    userTag: String? = nil,
    socialType: String? = nil,
    isNewUser: Bool? = nil,
    errorDescription: String? = nil
  ) {
    self.username = username
    self.userTag = userTag
    self.socialType = socialType
    self.isNewUser = isNewUser
    self.errorDescription = errorDescription
  }
}

public enum BattleEventType: String, Sendable {
  case viewed = "battle_viewed"
  case detailOpened = "battle_detail_opened"
  case prevoteSubmitted = "battle_prevote_submitted"
  case postvoteSubmitted = "battle_postvote_submitted"
}

public struct BattleEventData: Sendable {
  public let battleID: Int?
  public let battleTitle: String?
  public let voteSide: String?
  public let source: String?

  public init(
    battleID: Int? = nil,
    battleTitle: String? = nil,
    voteSide: String? = nil,
    source: String? = nil
  ) {
    self.battleID = battleID
    self.battleTitle = battleTitle
    self.voteSide = voteSide
    self.source = source
  }
}

public enum SessionEventType: String, Sendable {
  case logoutSucceeded = "logout_succeeded"
}

public struct SessionEventData: Sendable {
  public let provider: String

  public init(provider: String) {
    self.provider = provider
  }
}

// MARK: - UseCase

public struct AnalyticsUseCase: Sendable {
  public var track: @Sendable (_ event: AnalyticsEvent) -> Void

  public init(track: @escaping @Sendable (_ event: AnalyticsEvent) -> Void) {
    self.track = track
  }
}

extension AnalyticsUseCase: DependencyKey {
  public static let liveValue = AnalyticsUseCase { event in
    let mixpanel = Mixpanel.mainInstance()
    let userSession = currentUserSession()

    switch event {
    case let .auth(type, data):
      if type == .loginSucceeded || type == .signupSucceeded {
        identifyIfPossible(
          mixpanel: mixpanel,
          userTag: data.userTag,
          socialType: data.socialType,
          isNewUser: data.isNewUser,
          username: data.username
        )
      }
      let properties = authProperties(data, userSession: userSession)
      #logDebug("Mixpanel track", ["event": type.rawValue, "properties": String(describing: properties)])
      mixpanel.track(event: type.rawValue, properties: properties)

    case let .battle(type, data):
      let properties = battleProperties(data, userSession: userSession)
      #logDebug("Mixpanel track", ["event": type.rawValue, "properties": String(describing: properties)])
      mixpanel.track(event: type.rawValue, properties: properties)

    case let .session(type, data):
      let properties = sessionProperties(data, userSession: userSession)
      #logDebug("Mixpanel track", ["event": type.rawValue, "properties": String(describing: properties)])
      mixpanel.track(event: type.rawValue, properties: properties)
      if type == .logoutSucceeded {
        mixpanel.reset()
        MPSessionReplay.getInstance()?.identify(distinctId: mixpanel.distinctId)
      }
    }
  }

  public static let testValue = AnalyticsUseCase { _ in }
  public static let previewValue = testValue

  private static func identifyIfPossible(
    mixpanel: MixpanelInstance,
    userTag: String?,
    socialType: String?,
    isNewUser: Bool?,
    username: String?
  ) {
    let distinctID = userTag?.nilIfEmpty
      ?? username?.nilIfEmpty
      ?? "\(socialType ?? "unknown")-\(UUID().uuidString)"
    mixpanel.identify(distinctId: distinctID)
    MPSessionReplay.getInstance()?.identify(distinctId: distinctID)

    var properties: Properties = [:]
    if let socialType {
      properties["provider"] = socialType
    }
    if let isNewUser {
      properties["is_new_user"] = isNewUser
    }
    if let username, !username.isEmpty {
      properties["$name"] = username
      properties["username"] = username
    }
    if let userTag, !userTag.isEmpty {
      properties["user_tag"] = userTag
    }

    guard !properties.isEmpty else { return }
    mixpanel.people.set(properties: properties)
  }

  private static func authProperties(_ data: AuthEventData, userSession: UserSession) -> Properties {
    var properties = commonUserProperties(userSession: userSession)
    if let username = data.username {
      properties["username"] = username
    }
    if let userTag = data.userTag {
      properties["user_tag"] = userTag
    }
    if let socialType = data.socialType {
      properties["social_type"] = socialType
    }
    if let isNewUser = data.isNewUser {
      properties["is_new_user"] = isNewUser
    }
    if let errorDescription = data.errorDescription {
      properties["error_description"] = errorDescription
    }
    return properties
  }

  private static func battleProperties(_ data: BattleEventData, userSession: UserSession) -> Properties {
    var properties = commonUserProperties(userSession: userSession)
    if let battleID = data.battleID {
      properties["battle_id"] = battleID
    }
    if let battleTitle = data.battleTitle {
      properties["battle_title"] = battleTitle
    }
    if let voteSide = data.voteSide {
      properties["vote_side"] = voteSide
    }
    if let source = data.source {
      properties["source"] = source
    }
    return properties
  }

  private static func sessionProperties(_ data: SessionEventData, userSession: UserSession) -> Properties {
    var properties = commonUserProperties(userSession: userSession)
    properties["provider"] = data.provider
    return properties
  }

  private static func currentUserSession() -> UserSession {
    @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty
    return userSession
  }

  private static func commonUserProperties(userSession: UserSession) -> Properties {
    var properties: Properties = [:]
    if !userSession.name.isEmpty {
      properties["username"] = userSession.name
    }
    properties["provider"] = userSession.provider.rawValue
    return properties
  }
}

public extension DependencyValues {
  var analyticsUseCase: AnalyticsUseCase {
    get { self[AnalyticsUseCase.self] }
    set { self[AnalyticsUseCase.self] = newValue }
  }
}

private extension String {
  var nilIfEmpty: String? { isEmpty ? nil : self }
}
