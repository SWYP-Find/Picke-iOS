//
//  NotificationSettingsDataDTO.swift
//  ProfileDomain
//
//  Created by Picke on 10/11/26.
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
