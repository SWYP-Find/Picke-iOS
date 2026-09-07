//
//  NotificationSettingSection.swift
//  Entity
//

import Foundation

/// 알림 설정 섹션.
public enum NotificationSettingSection: String, CaseIterable, Identifiable, Equatable {
  case feature
  case social
  case marketing

  public var id: String { rawValue }

  public var title: String {
    switch self {
    case .feature: "기능별 알림 설정"
    case .social: "소셜 알림 설정"
    case .marketing: "마케팅 알림 설정"
    }
  }

  /// 섹션에 속한 항목들.
  public var keys: [NotificationSettingKey] {
    NotificationSettingKey.allCases.filter { $0.section == self }
  }
}
