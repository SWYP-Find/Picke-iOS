//
//  NotificationSettingsRequest.swift
//  Service
//

import Foundation

public struct NotificationSettingsRequest: Encodable {
  public let newBattleEnabled: Bool
  public let battleResultEnabled: Bool
  public let commentReplyEnabled: Bool
  public let newCommentEnabled: Bool
  public let contentLikeEnabled: Bool
  public let marketingEventEnabled: Bool

  public init(
    newBattleEnabled: Bool,
    battleResultEnabled: Bool,
    commentReplyEnabled: Bool,
    newCommentEnabled: Bool,
    contentLikeEnabled: Bool,
    marketingEventEnabled: Bool
  ) {
    self.newBattleEnabled = newBattleEnabled
    self.battleResultEnabled = battleResultEnabled
    self.commentReplyEnabled = commentReplyEnabled
    self.newCommentEnabled = newCommentEnabled
    self.contentLikeEnabled = contentLikeEnabled
    self.marketingEventEnabled = marketingEventEnabled
  }
}
