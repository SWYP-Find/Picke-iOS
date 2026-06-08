//
//  MyPage.swift
//  Entity
//
//  `GET /api/v1/me/mypage` 응답 도메인 모델.
//  프로필 / 철학자 유형 / 티어(포인트) 3개 섹션.
//

import Foundation

public struct MyPage: Equatable {
  public let profile: MyProfile
  public let philosopher: MyPhilosopher
  public let tier: MyTier

  public init(
    profile: MyProfile,
    philosopher: MyPhilosopher,
    tier: MyTier
  ) {
    self.profile = profile
    self.philosopher = philosopher
    self.tier = tier
  }
}

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
}

public struct MyPhilosopher: Equatable {
  /// 철학자 유형 코드 (예: `SOCRATES`).
  public let philosopherType: String
  public let philosopherLabel: String
  /// 유형명 (예: `??형`).
  public let typeName: String
  public let description: String
  public let imageURL: String

  public init(
    philosopherType: String,
    philosopherLabel: String,
    typeName: String,
    description: String,
    imageURL: String
  ) {
    self.philosopherType = philosopherType
    self.philosopherLabel = philosopherLabel
    self.typeName = typeName
    self.description = description
    self.imageURL = imageURL
  }
}

public struct MyTier: Equatable {
  /// 티어 코드 (예: `WANDERER`).
  public let tierCode: String
  public let tierLabel: String
  /// 보유 포인트.
  public let currentPoint: Int

  public init(
    tierCode: String,
    tierLabel: String,
    currentPoint: Int
  ) {
    self.tierCode = tierCode
    self.tierLabel = tierLabel
    self.currentPoint = currentPoint
  }
}
