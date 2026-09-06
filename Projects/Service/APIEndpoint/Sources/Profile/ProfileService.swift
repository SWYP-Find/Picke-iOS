//
//  ProfileService.swift
//  Service
//

import Foundation

import API
import NetworkHeader


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

extension ProfileService: PickeTargetType {
  public typealias Domain = PieckeDomain

  public var domain: PieckeDomain { .profile }

  public var urlPath: String {
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

  public var parameters: [String: Any]? {
    switch self {
    case .mypage:
      return nil
    case .recap:
      return nil
    case let .creditsHistory(query):
      guard let dict = query.toDictionary else { return nil }
      return dict.isEmpty ? nil : dict
    case let .battleRecords(query):
      guard let dict = query.toDictionary else { return nil }
      return dict.isEmpty ? nil : dict
    case let .contentActivities(query):
      guard let dict = query.toDictionary else { return nil }
      return dict.isEmpty ? nil : dict
    case .notificationSettings:
      return nil
    case let .updateNotificationSettings(body):
      guard let dict = body.toDictionary else { return nil }
      return dict.isEmpty ? nil : dict
    case let .updateProfile(body):
      guard let dict = body.toDictionary else { return nil }
      return dict.isEmpty ? nil : dict
    }
  }

  public var headers: [String: String]? {
    return APIHeader.baseHeader
  }
}
