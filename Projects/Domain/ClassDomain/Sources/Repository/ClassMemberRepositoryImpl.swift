import ClassDomainInterface
import Dependencies
import Foundation
import PickeNetwork

public struct ClassMemberRepositoryImpl: ClassMemberInterface {
  @Dependency(\.networkClient) private var client

  public init() {}

  public func fetchMembers(classID: Int) async throws -> ClassMemberList {
    do {
      let data = try await client.send(
        ClassMemberService.members(classID: classID),
        as: [ClassMemberDTO].self
      )
      return try ClassMemberDTO.toMemberList(data)
    } catch {
      throw Self.classError(error)
    }
  }

  public func updateMyDisplayName(classID: Int, name: String) async throws -> ClassMember {
    do {
      let data = try await client.send(
        ClassMemberService.updateMyName(classID: classID, name: name),
        as: ClassMemberDTO.self
      )
      return data.toDomain()
    } catch {
      throw Self.classError(error)
    }
  }

  public func removeMember(classID: Int, memberID: Int) async throws {
    do {
      _ = try await client.send(
        ClassMemberService.remove(classID: classID, memberID: memberID),
        as: PickeEmptyResponse.self
      )
    } catch {
      throw Self.classError(error)
    }
  }

  private static func classError(_ error: Error) -> ClassError {
    guard let networkError = error as? PickeNetworkError else { return ClassError.from(error) }
    if case let .response(response) = networkError {
      switch response.code {
      case "CLASS_409_NAME": return .duplicateName
      default: return .network(response.message ?? "멤버 요청을 처리하지 못했어요.")
      }
    }
    return ClassError.from(networkError)
  }
}
