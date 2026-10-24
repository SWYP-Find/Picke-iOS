//
//  ClassInterface.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/11/26.
//

import ComposableArchitecture
import Foundation

public protocol ClassInterface: Sendable {
  func fetchMyClasses() async throws -> [ClassRoom]
  func fetchRecommendedBattles(filter: ClassTopicFilter) async throws -> [ClassBattleSummary]
  func createClass(_ creation: ClassCreation) async throws -> ClassRoom
  func fetchClass(id: Int) async throws -> ClassRoom
  func fetchClass(joinCode: String) async throws -> ClassRoom
  func fetchClassPreview(joinCode: String) async throws -> ClassJoinPreview
  func joinClass(joinCode: String, nickname: String) async throws -> ClassRoom
  func updateDeadline(id: Int, deadline: Date) async throws -> ClassRoom
  func deleteClass(id: Int) async throws
  func leaveClass(id: Int) async throws
  func fetchReport(roomID: Int) async throws -> ClassReport?
  func fetchOwnerDashboard(roomID: Int) async throws -> ClassOwnerDashboardData?
}

public extension ClassInterface {
  func fetchClassPreview(joinCode: String) async throws -> ClassJoinPreview {
    let room = try await fetchClass(joinCode: joinCode)
    return ClassJoinPreview(room: room)
  }
}

public enum ClassRepositoryDependency: TestDependencyKey {
  public static var testValue: any ClassInterface {
    MockClassRepository()
  }
}

public enum ClassUseCaseDependency: TestDependencyKey {
  public static var testValue: any ClassInterface {
    MockClassRepository()
  }
}

public enum ClassMockRepositoryDependency: TestDependencyKey {
  public static var testValue: MockClassRepository? {
    nil
  }
}

public extension DependencyValues {
  var classRepository: any ClassInterface {
    get { self[ClassRepositoryDependency.self] }
    set { self[ClassRepositoryDependency.self] = newValue }
  }

  var classUseCase: any ClassInterface {
    get { self[ClassUseCaseDependency.self] }
    set { self[ClassUseCaseDependency.self] = newValue }
  }

  var classMockRepository: MockClassRepository? {
    get { self[ClassMockRepositoryDependency.self] }
    set { self[ClassMockRepositoryDependency.self] = newValue }
  }
}
