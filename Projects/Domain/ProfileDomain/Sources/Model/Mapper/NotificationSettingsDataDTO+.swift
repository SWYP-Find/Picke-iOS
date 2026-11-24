//
//  NotificationSettingsDataDTO+.swift
//  ProfileDomain
//
//  Created by Picke on 10/11/26.
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
