//
//  ProfileService.swift
//  Service
//

import Foundation

import API
import PickeNetwork

public enum ProfileService {
  case mypage
  case recap
  case creditsHistory(query: CreditHistoryQueryRequest)
  case battleRecords(query: BattleRecordsQueryRequest)
  case contentActivities(query: ContentActivitiesQueryRequest)
  case notificationSettings
  case updateNotificationSettings(body: NotificationSettingsRequest)
  case updateProfile(body: ProfileUpdateRequest)
}

extension ProfileService: PickeDataRequest {
  public var domain: any PickeDomainType { PieckeDomain.profile }

  public var path: String {
    switch self {
    case .mypage:
      return ProfileAPI.mypage.description
    case .recap:
      return ProfileAPI.recap.description
    case .creditsHistory:
      return ProfileAPI.creditsHistory.description
    case .battleRecords:
      return ProfileAPI.battleRecords.description
    case .contentActivities:
      return ProfileAPI.contentActivities.description
    case .notificationSettings:
      return ProfileAPI.notificationSettings.description
    case .updateNotificationSettings:
      return ProfileAPI.notificationSettings.description
    case .updateProfile:
      return ProfileAPI.profile.description
    }
  }

  public var method: HTTPMethod {
    switch self {
    case .mypage, .recap, .creditsHistory, .battleRecords, .contentActivities, .notificationSettings:
      return .get
    case .updateNotificationSettings, .updateProfile:
      return .patch
    }
  }

  public var parameters: (any Encodable & Sendable)? {
    switch self {
    case let .creditsHistory(query):
      return query
    case let .battleRecords(query):
      return query
    case let .contentActivities(query):
      return query
    case let .updateNotificationSettings(body):
      return body
    case let .updateProfile(body):
      return body
    case .mypage, .recap, .notificationSettings:
      return nil
    }
  }
}
