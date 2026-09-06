//
//  PerspectiveCommentUser.swift
//  Entity
//

import Foundation

public struct PerspectiveCommentUser: Equatable, Hashable {
  public let userTag: String
  public let nickname: String
  public let characterType: String
  public let characterImageUrl: String?

  public init(
    userTag: String,
    nickname: String,
    characterType: String,
    characterImageUrl: String?
  ) {
    self.userTag = userTag
    self.nickname = nickname
    self.characterType = characterType
    self.characterImageUrl = characterImageUrl
  }
}
