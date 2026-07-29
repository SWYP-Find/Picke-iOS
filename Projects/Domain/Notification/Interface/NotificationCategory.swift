//
//  NotificationCategory.swift
//  Entity
//

import Foundation

public enum NotificationCategory: String, Equatable, CaseIterable, Identifiable {
  case all = "ALL"
  case content = "CONTENT"
  case notice = "NOTICE"
  case event = "EVENT"

  public var id: String { rawValue }

  /// 탭 표시명.
  public var title: String {
    switch self {
    case .all: "전체"
    case .content: "콘텐츠"
    case .notice: "공지사항"
    case .event: "이벤트"
    }
  }

  public init(rawValue: String) {
    switch rawValue.uppercased() {
    case "CONTENT": self = .content
    case "NOTICE": self = .notice
    case "EVENT": self = .event
    default: self = .all
    }
  }
}
