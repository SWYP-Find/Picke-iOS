//
//  BattlePerspective.swift
//  Entity
//

import Foundation

public struct BattlePerspective: Equatable, Identifiable, Hashable {
  public let perspectiveId: Int
  public let user: BattlePerspectiveUser
  public let option: BattlePerspectiveOption
  public let content: String
  public let likeCount: Int
  public let commentCount: Int
  public let isLiked: Bool
  public let isMyPerspective: Bool
  public let createdAt: Date?

  public var id: Int { perspectiveId }

  public init(
    perspectiveId: Int,
    user: BattlePerspectiveUser,
    option: BattlePerspectiveOption,
    content: String,
    likeCount: Int,
    commentCount: Int,
    isLiked: Bool,
    isMyPerspective: Bool,
    createdAt: Date?
  ) {
    self.perspectiveId = perspectiveId
    self.user = user
    self.option = option
    self.content = content
    self.likeCount = likeCount
    self.commentCount = commentCount
    self.isLiked = isLiked
    self.isMyPerspective = isMyPerspective
    self.createdAt = createdAt
  }
}
