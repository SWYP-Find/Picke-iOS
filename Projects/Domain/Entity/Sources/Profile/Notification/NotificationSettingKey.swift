//
//  NotificationSettingKey.swift
//  Entity
//

import Foundation

/// 알림 설정 항목.
public enum NotificationSettingKey: String, CaseIterable, Identifiable, Equatable {
  case newBattle
  case battleResult
  case commentReply
  case newComment
  case contentLike
  case marketingEvent

  public var id: String { rawValue }

  public var title: String {
    switch self {
    case .newBattle: "새 배틀 알림"
    case .battleResult: "투표 결과 알림"
    case .commentReply: "내 댓글에 답글 알림"
    case .newComment: "새 댓글 알림"
    case .contentLike: "좋아요 알림"
    case .marketingEvent: "이벤트 및 소식 알림"
    }
  }

  public var subtitle: String {
    switch self {
    case .newBattle: "관심 분야의 새로운 배틀이 열리면 알려드려요"
    case .battleResult: "참여한 배틀의 최종 결과를 알려드려요"
    case .commentReply: "내 의견에 답글이 달리면 알려드려요"
    case .newComment: "참여한 배틀에 새 댓글이 달리면 알려드려요"
    case .contentLike: "내 의견에 좋아요가 눌리면 알려드려요"
    case .marketingEvent: "다양한 이벤트와 새로운 소식을 알려드려요"
    }
  }

  public var section: NotificationSettingSection {
    switch self {
    case .newBattle, .battleResult: .feature
    case .commentReply, .newComment, .contentLike: .social
    case .marketingEvent: .marketing
    }
  }
}
