//
//  NotificationInterface.swift
//  NotificationInterface
//

import Foundation

/// NotificationCoordinator 진입 입력값.
public enum NotificationRoute: Equatable, Sendable {
  case inbox
}

/// 알림함 화면이 상위 coordinator 로 올려보내는 delegate 계약.
public enum NotificationDelegate: Equatable, Sendable {
  /// 알림함 닫기(뒤로) 요청.
  case dismiss
}

public enum NotificationInterface {}
