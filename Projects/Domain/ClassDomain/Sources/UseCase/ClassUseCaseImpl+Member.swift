import ClassDomainInterface
import Foundation

extension ClassUseCaseImpl {
  public func fetchMembers(classID: Int) async throws -> ClassMemberList {
    try await repository.fetchMembers(classID: classID)
  }

  public func updateMyDisplayName(classID: Int, name: String) async throws -> ClassMember {
    try await repository.updateMyDisplayName(classID: classID, name: name)
  }

  public func removeMember(classID: Int, memberID: Int) async throws {
    try await repository.removeMember(classID: classID, memberID: memberID)
  }
}
