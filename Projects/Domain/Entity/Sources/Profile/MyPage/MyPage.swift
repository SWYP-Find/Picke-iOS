//
//  MyPage.swift
//  Entity
//
//  `GET /api/v1/me/mypage` 응답 도메인 모델 (프로필 / 철학자 / 티어).
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
