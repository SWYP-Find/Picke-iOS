//
//  NotificationInterface.swift
//  NotificationInterface
//
//  Notification 피쳐의 public 계약(delegate). 구현(NotificationFeature/View)은 Notification 타깃에 유지한다.
//  다른 피쳐(Home/Hifi/Profile)는 이 Interface 에만 의존하는 것을 목표로 한다. (문서 3~4단계)
//

import Foundation

/// 알림함 화면이 상위 coordinator 로 올려보내는 delegate 계약.
public enum NotificationDelegate: Equatable, Sendable {
  /// 알림함 닫기(뒤로) 요청.
  case dismiss
}

public enum NotificationInterface {}
