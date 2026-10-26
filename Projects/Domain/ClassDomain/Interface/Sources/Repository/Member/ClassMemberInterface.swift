//
//  ClassMemberInterface.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/26/26.
//

import ComposableArchitecture
import Foundation

public protocol ClassMemberInterface: Sendable {
  func fetchMembers(classID: Int) async throws -> ClassMemberList
  func updateMyDisplayName(classID: Int, name: String) async throws -> ClassMember
  func removeMember(classID: Int, memberID: Int) async throws
}

public enum ClassMemberRepositoryDependency: TestDependencyKey {
  public static var testValue: any ClassMemberInterface {
    MockClassRepository()
  }
}

public enum ClassMemberUseCaseDependency: TestDependencyKey {
  public static var testValue: any ClassMemberInterface {
    MockClassRepository()
  }
}

public extension DependencyValues {
  var classMemberRepository: any ClassMemberInterface {
    get { self[ClassMemberRepositoryDependency.self] }
    set { self[ClassMemberRepositoryDependency.self] = newValue }
  }

  var classMemberUseCase: any ClassMemberInterface {
    get { self[ClassMemberUseCaseDependency.self] }
    set { self[ClassMemberUseCaseDependency.self] = newValue }
  }
}
