//
//  MyProfile.swift
//  Entity
//

import Foundation

public struct MyProfile: Equatable {
  /// 사용자 코드 (`@` 표기에 사용).
  public let userTag: String
  public let nickname: String
  /// 캐릭터 유형 코드 (예: `OWL`).
  public let characterType: String
  public let characterLabel: String
  public let characterImageURL: String
  /// 매너 온도.
  public let mannerTemperature: Double

  public init(
    userTag: String,
    nickname: String,
    characterType: String,
    characterLabel: String,
    characterImageURL: String,
    mannerTemperature: Double
  ) {
    self.userTag = userTag
    self.nickname = nickname
    self.characterType = characterType
    self.characterLabel = characterLabel
    self.characterImageURL = characterImageURL
    self.mannerTemperature = mannerTemperature
  }

  public static let empty = MyProfile(
    userTag: "",
    nickname: "",
    characterType: "",
    characterLabel: "",
    characterImageURL: "",
    mannerTemperature: 0
  )
}
