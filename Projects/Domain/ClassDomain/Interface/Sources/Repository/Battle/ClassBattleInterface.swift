//
//  ClassBattleInterface.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/26/26.
//

import ComposableArchitecture
import Foundation

public protocol ClassBattleInterface: Sendable {
  func fetchBattle(classID: Int) async throws -> ClassBattleSession
  func submitPreVote(classID: Int, optionID: Int) async throws -> ClassVoteReceipt
  func completeTTS(classID: Int) async throws
  func submitPostVote(classID: Int, optionID: Int) async throws -> ClassVoteReceipt
  func fetchMyVotes(classID: Int) async throws -> ClassVoteHistory
  func fetchVoteStats(classID: Int) async throws -> ClassVoteStats
  func publishPerspective(classID: Int, content: String) async throws -> ClassPerspectiveReceipt
  func fetchPerspectives(
    classID: Int,
    cursor: String?,
    size: Int?,
    optionID: Int?,
    sort: String?
  ) async throws -> ClassPerspectivePage
  func fetchMyPerspectives(classID: Int) async throws -> [ClassPerspectiveItem]
}

public enum ClassBattleRepositoryDependency: TestDependencyKey {
  public static var testValue: any ClassBattleInterface {
    MockClassRepository()
  }
}

public enum ClassBattleUseCaseDependency: TestDependencyKey {
  public static var testValue: any ClassBattleInterface {
    MockClassRepository()
  }
}

public extension DependencyValues {
  var classBattleRepository: any ClassBattleInterface {
    get { self[ClassBattleRepositoryDependency.self] }
    set { self[ClassBattleRepositoryDependency.self] = newValue }
  }

  var classBattleUseCase: any ClassBattleInterface {
    get { self[ClassBattleUseCaseDependency.self] }
    set { self[ClassBattleUseCaseDependency.self] = newValue }
  }
}
