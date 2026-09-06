//
//  NotificationSettingsDataDTO.swift
//  ProfileDomain
//

import PickeNetworkInterface
import Foundation

public struct NotificationSettingsDataDTO: Decodable {
  public let newBattleEnabled: Bool?
  public let battleResultEnabled: Bool?
  public let commentReplyEnabled: Bool?
  public let newCommentEnabled: Bool?
  public let contentLikeEnabled: Bool?
  public let marketingEventEnabled: Bool?
}

public typealias NotificationSettingsResponseDTO = BaseResponseDTO<NotificationSettingsDataDTO>
