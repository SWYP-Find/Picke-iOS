//
//  ClassRoomInterface.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/26/26.
//

import ComposableArchitecture
import Foundation

public protocol ClassRoomInterface: Sendable {
  func fetchMyClasses() async throws -> [ClassRoom]
  func createClass(_ creation: ClassCreation) async throws -> ClassRoom
  func fetchClass(id: Int) async throws -> ClassRoom
  func fetchClass(joinCode: String) async throws -> ClassRoom
  func fetchClassPreview(joinCode: String) async throws -> ClassJoinPreview
  func joinClass(joinCode: String, nickname: String) async throws -> ClassRoom
  func updateDeadline(id: Int, deadline: Date) async throws -> ClassRoom
  func updateName(id: Int, name: String) async throws -> ClassRoom
  /// Android `PATCH /classes/{id}` — 이름과(바뀐 경우) 마감일을 한 번에 보낸다.
  func updateClass(id: Int, name: String, deadline: Date?) async throws -> ClassRoom
  func deleteClass(id: Int) async throws
  func leaveClass(id: Int) async throws
}

public extension ClassRoomInterface {
  func updateName(id _: Int, name _: String) async throws -> ClassRoom {
    throw ClassError.userMessage("클래스 이름 변경을 지원하지 않습니다.")
  }

  /// 단일 PATCH 를 지원하지 않는 테스트 대역용 기본 구현.
  func updateClass(id: Int, name: String, deadline: Date?) async throws -> ClassRoom {
    var updated = try await updateName(id: id, name: name)
    if let deadline {
      updated = try await updateDeadline(id: id, deadline: deadline)
    }
    return updated
  }

  func fetchClassPreview(joinCode: String) async throws -> ClassJoinPreview {
    let room = try await fetchClass(joinCode: joinCode)
    return ClassJoinPreview(room: room)
  }
}

public enum ClassRoomRepositoryDependency: TestDependencyKey {
  public static var testValue: any ClassRoomInterface {
    MockClassRepository()
  }
}

public enum ClassRoomUseCaseDependency: TestDependencyKey {
  public static var testValue: any ClassRoomInterface {
    MockClassRepository()
  }
}

public extension DependencyValues {
  var classRoomRepository: any ClassRoomInterface {
    get { self[ClassRoomRepositoryDependency.self] }
    set { self[ClassRoomRepositoryDependency.self] = newValue }
  }

  var classRoomUseCase: any ClassRoomInterface {
    get { self[ClassRoomUseCaseDependency.self] }
    set { self[ClassRoomUseCaseDependency.self] = newValue }
  }
}
