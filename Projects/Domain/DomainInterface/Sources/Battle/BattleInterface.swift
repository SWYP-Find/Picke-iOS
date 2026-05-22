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
  func fetchVoteStats(battleId: Int) async throws -> BattleVoteStats
  func fetchPerspectives(
    battleId: Int,
    cursor: String?,
    size: Int?,
    optionLabel: String?,
    sort: BattlePerspectiveSort?
  ) async throws -> BattlePerspectivePage
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
