//
//  ProfileUpdateRequest.swift
//  ProfileData
//

import Foundation

public struct ProfileUpdateRequest: Encodable, Sendable {
  public let nickname: String
  public let characterType: String

  public init(
    nickname: String,
    characterType: String
  ) {
    self.nickname = nickname
    self.characterType = characterType
  }
}
