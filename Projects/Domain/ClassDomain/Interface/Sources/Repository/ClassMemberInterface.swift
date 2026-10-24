import ComposableArchitecture
import Foundation

public protocol ClassMemberInterface: Sendable {
  func fetchMembers(classID: Int) async throws -> ClassMemberList
  func updateMyDisplayName(classID: Int, name: String) async throws -> ClassMember
  func removeMember(classID: Int, memberID: Int) async throws
}

public enum ClassMemberRepositoryDependency: TestDependencyKey {
  public static var testValue: any ClassMemberInterface {
    UnimplementedClassMemberInterface()
  }
}

public enum ClassMemberUseCaseDependency: TestDependencyKey {
  public static var testValue: any ClassMemberInterface {
    UnimplementedClassMemberInterface()
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

private struct UnimplementedClassMemberInterface: ClassMemberInterface {
  func fetchMembers(classID _: Int) async throws -> ClassMemberList {
    throw ClassError.unknown("멤버 데이터를 불러올 수 없어요.")
  }

  func updateMyDisplayName(classID _: Int, name _: String) async throws -> ClassMember {
    throw ClassError.unknown("이름 변경을 사용할 수 없어요.")
  }

  func removeMember(classID _: Int, memberID _: Int) async throws {
    throw ClassError.unknown("멤버 변경을 사용할 수 없어요.")
  }
}
