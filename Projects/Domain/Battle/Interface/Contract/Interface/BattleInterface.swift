//
//  BattleInterface.swift
//  DomainInterface
//

import CommonDomainInterface
import Foundation
import HomeDomainInterface
import ComposableArchitecture

public protocol BattleInterface: Sendable {
  func fetchTodayBattles() async throws -> TodayBattlePage
  func fetchBattle(battleId: Int) async throws -> BattleDetail
  func submitPreVote(
    battleId: Int,
    optionId: Int
  ) async throws -> PreVoteResult
  func submitPostVote(
    battleId: Int,
    optionId: Int
  ) async throws -> PreVoteResult
  func fetchScenario(battleId: Int) async throws -> BattleScenario
  func fetchVoteStats(battleId: Int) async throws -> BattleVoteStats
  func fetchPerspectives(
    battleId: Int,
    cursor: String?,
    size: Int?,
    optionId: Int?,
    sort: BattlePerspectiveSort?
  ) async throws -> BattlePerspectivePage
  /// 관점을 등록한다. 등록 직후 재조회가 실패하면 `nil` 을 반환한다 — 등록 자체는 성공한 상태다.
  func createPerspective(
    battleId: Int,
    content: String,
    optionId: Int?
  ) async throws -> BattlePerspective?
  func fetchMyPerspective(battleId: Int) async throws -> BattlePerspective?
  func fetchRecommendedBattles(battleId: Int) async throws -> RecommendedBattlePage
  func proposeBattle(_ draft: BattleProposalDraft) async throws -> BattleProposal
}

public enum BattleRepositoryDependency: TestDependencyKey {
  public static var testValue: BattleInterface { MockBattleRepository() }
}

public enum BattleUseCaseDependency: TestDependencyKey {
  public static var testValue: BattleInterface { MockBattleRepository() }
}

public extension DependencyValues {
  var battleRepository: BattleInterface {
    get { self[BattleRepositoryDependency.self] }
    set { self[BattleRepositoryDependency.self] = newValue }
  }
}

// UseCase 소비자용 별칭 — 인터페이스 강제(구현 모듈 import 불필요). pass-through 라 리포지토리 키로 해소.
public extension DependencyValues {
  var battleUseCase: BattleInterface {
    get { self[BattleUseCaseDependency.self] }
    set { self[BattleUseCaseDependency.self] = newValue }
  }
}
