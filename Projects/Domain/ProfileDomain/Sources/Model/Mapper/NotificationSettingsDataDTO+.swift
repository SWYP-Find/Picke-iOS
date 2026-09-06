//
//  NotificationSettingsDataDTO+.swift
//  ProfileDomain
//

import ProfileDomainInterface
import Foundation

public extension NotificationSettingsDataDTO {
  func toDomain() -> NotificationSettings {
    NotificationSettings(
      newBattleEnabled: newBattleEnabled ?? false,
      battleResultEnabled: battleResultEnabled ?? false,
      commentReplyEnabled: commentReplyEnabled ?? false,
      newCommentEnabled: newCommentEnabled ?? false,
      contentLikeEnabled: contentLikeEnabled ?? false,
      marketingEventEnabled: marketingEventEnabled ?? false
    )
  }
}
