//
//  MyPage.swift
//  Entity
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
