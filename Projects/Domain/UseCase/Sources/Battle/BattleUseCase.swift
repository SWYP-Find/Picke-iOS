//
//  BattleUseCase.swift
//  UseCase
//

import Foundation

import DomainInterface
import Entity

import ComposableArchitecture

public struct BattleUseCaseImpl: BattleInterface {
  @Dependency(\.battleRepository) private var battleRepository

  public init() {}

  public func fetchBattle(battleId: Int) async throws -> BattleDetail {
    return try await battleRepository.fetchBattle(battleId: battleId)
  }

  public func submitPreVote(
    battleId: Int,
    optionId: Int
  ) async throws -> PreVoteResult {
    return try await battleRepository.submitPreVote(battleId: battleId, optionId: optionId)
  }

  public func submitPostVote(
    battleId: Int,
    optionId: Int
  ) async throws -> PreVoteResult {
    return try await battleRepository.submitPostVote(battleId: battleId, optionId: optionId)
  }

  public func fetchScenario(battleId: Int) async throws -> BattleScenario {
    return try await battleRepository.fetchScenario(battleId: battleId)
  }

  public func fetchVoteStats(battleId: Int) async throws -> BattleVoteStats {
    return try await battleRepository.fetchVoteStats(battleId: battleId)
  }

  public func fetchPerspectives(
    battleId: Int,
    cursor: String?,
    size: Int?,
    optionId: Int?,
    sort: BattlePerspectiveSort?
  ) async throws -> BattlePerspectivePage {
    return try await battleRepository.fetchPerspectives(
      battleId: battleId,
      cursor: cursor,
      size: size,
      optionId: optionId,
      sort: sort
    )
  }

  public func createPerspective(
    battleId: Int,
    content: String,
    optionId: Int
  ) async throws -> BattlePerspective {
    return try await battleRepository.createPerspective(
      battleId: battleId,
      content: content,
      optionId: optionId
    )
  }

  public func fetchMyPerspective(battleId: Int) async throws -> BattlePerspective? {
    return try await battleRepository.fetchMyPerspective(battleId: battleId)
  }
}

extension BattleUseCaseImpl: DependencyKey {
  public static var liveValue = BattleUseCaseImpl()
  public static var testValue = BattleUseCaseImpl()
  public static var previewValue = BattleUseCaseImpl()
}

public extension DependencyValues {
  var battleUseCase: BattleUseCaseImpl {
    get { self[BattleUseCaseImpl.self] }
    set { self[BattleUseCaseImpl.self] = newValue }
  }
}
