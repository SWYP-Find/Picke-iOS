//
//  NotificationSettingsDataDTO.swift
//  Model
//

import Foundation
import Model

public struct NotificationSettingsDataDTO: Decodable {
  public let newBattleEnabled: Bool?
  public let battleResultEnabled: Bool?
  public let commentReplyEnabled: Bool?
  public let newCommentEnabled: Bool?
  public let contentLikeEnabled: Bool?
  public let marketingEventEnabled: Bool?
}

public typealias NotificationSettingsResponseDTO = BaseResponseDTO<NotificationSettingsDataDTO>
