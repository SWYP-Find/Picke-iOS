//
//  NotificationSettings.swift
//  Entity
//

import Foundation

public struct NotificationSettings: Equatable {
  public var newBattleEnabled: Bool
  public var battleResultEnabled: Bool
  public var commentReplyEnabled: Bool
  public var newCommentEnabled: Bool
  public var contentLikeEnabled: Bool
  public var marketingEventEnabled: Bool

  public init(
    newBattleEnabled: Bool = false,
    battleResultEnabled: Bool = false,
    commentReplyEnabled: Bool = false,
    newCommentEnabled: Bool = false,
    contentLikeEnabled: Bool = false,
    marketingEventEnabled: Bool = false
  ) {
    self.newBattleEnabled = newBattleEnabled
    self.battleResultEnabled = battleResultEnabled
    self.commentReplyEnabled = commentReplyEnabled
    self.newCommentEnabled = newCommentEnabled
    self.contentLikeEnabled = contentLikeEnabled
    self.marketingEventEnabled = marketingEventEnabled
  }

  /// 키별 on/off 조회.
  public func isOn(_ key: NotificationSettingKey) -> Bool {
    switch key {
    case .newBattle: newBattleEnabled
    case .battleResult: battleResultEnabled
    case .commentReply: commentReplyEnabled
    case .newComment: newCommentEnabled
    case .contentLike: contentLikeEnabled
    case .marketingEvent: marketingEventEnabled
    }
  }

  /// 키별 on/off 설정 (불변 갱신).
  public func setting(_ key: NotificationSettingKey, to value: Bool) -> NotificationSettings {
    var copy = self
    switch key {
    case .newBattle: copy.newBattleEnabled = value
    case .battleResult: copy.battleResultEnabled = value
    case .commentReply: copy.commentReplyEnabled = value
    case .newComment: copy.newCommentEnabled = value
    case .contentLike: copy.contentLikeEnabled = value
    case .marketingEvent: copy.marketingEventEnabled = value
    }
    return copy
  }
}
