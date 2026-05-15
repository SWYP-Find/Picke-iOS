//
//  HomeBundle.swift
//  Entity
//
//  Created by Wonji Suh on 5/16/26.
//

import Foundation

/// `GET /api/v1/home` 응답을 화면 단위로 묶은 도메인 컨테이너.
public struct HomeBundle: Equatable {
  public let newNotice: Bool
  public let heroes: [HeroBattle]
  public let hotBattles: [HotBattle]
  public let bestBattles: [BestBattle]
  public let quizzes: [QuizQuestion]
  public let votes: [VoteQuestion]
  public let newBattles: [NewBattle]

  public init(
    newNotice: Bool,
    heroes: [HeroBattle],
    hotBattles: [HotBattle],
    bestBattles: [BestBattle],
    quizzes: [QuizQuestion],
    votes: [VoteQuestion],
    newBattles: [NewBattle]
  ) {
    self.newNotice = newNotice
    self.heroes = heroes
    self.hotBattles = hotBattles
    self.bestBattles = bestBattles
    self.quizzes = quizzes
    self.votes = votes
    self.newBattles = newBattles
  }
}

public extension HomeBundle {
  static let mock = HomeBundle(
    newNotice: true,
    heroes: HeroBattle.mocks,
    hotBattles: HotBattle.mocks,
    bestBattles: BestBattle.mocks,
    quizzes: [.mock],
    votes: [.mock],
    newBattles: NewBattle.mocks
  )
}
