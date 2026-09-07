//
//  UpdatedProfile.swift
//  ProfileDomainInterface
//

import Foundation

public struct UpdatedProfile: Equatable {
  public let userTag: String
  public let nickname: String
  public let characterType: String
  public let updatedAt: String

  public init(
    userTag: String,
    nickname: String,
    characterType: String,
    updatedAt: String
  ) {
    self.userTag = userTag
    self.nickname = nickname
    self.characterType = characterType
    self.updatedAt = updatedAt
  }
}
