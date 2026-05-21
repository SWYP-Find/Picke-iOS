//
//  BattleInterface.swift
//  DomainInterface
//

import Entity
import Foundation
import WeaveDI

public protocol BattleInterface: Sendable {
  func fetchBattle(battleId: Int) async throws -> BattleDetail
  func submitPreVote(battleId: Int, optionId: Int) async throws -> PreVoteResult
  func submitPostVote(battleId: Int, optionId: Int) async throws -> PreVoteResult
  func fetchScenario(battleId: Int) async throws -> BattleScenario
}

public struct BattleRepositoryDependency: DependencyKey {
  public static var liveValue: BattleInterface {
    UnifiedDI.resolve(BattleInterface.self) ?? DefaultBattleRepositoryImpl()
  }

  public static var testValue: BattleInterface {
    UnifiedDI.resolve(BattleInterface.self) ?? DefaultBattleRepositoryImpl()
  }

  public static var previewValue: BattleInterface = liveValue
}

public extension DependencyValues {
  var battleRepository: BattleInterface {
    get { self[BattleRepositoryDependency.self] }
    set { self[BattleRepositoryDependency.self] = newValue }
  }
}
