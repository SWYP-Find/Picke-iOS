//
//  NoticeTab.swift
//  Entity
//
//  공지사항 · 이벤트 탭.
//

import Foundation

public enum NoticeTab: String, CaseIterable, Identifiable, Equatable {
  case notice = "NOTICE"
  case event = "EVENT"

  public var id: String { rawValue }

  /// 탭 표시명.
  public var title: String {
    switch self {
    case .notice: "공지사항"
    case .event: "이벤트"
    }
  }
}
