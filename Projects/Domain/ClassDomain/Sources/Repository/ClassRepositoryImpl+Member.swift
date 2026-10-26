//
//  ClassRepositoryImpl+Member.swift
//  ClassDomain
//
//  Created by Picke on 10/26/26.
//

import APIEndpoint
import ClassDomainInterface
import Foundation
import PickeNetwork

extension ClassRepositoryImpl {
  public func fetchMembers(classID: Int) async throws -> ClassMemberList {
    do {
      let data = try await client.send(
        ClassMemberService.members(classID: classID),
        as: [ClassMemberDTO].self
      )
      return try ClassMemberDTO.toMemberList(data)
    } catch {
      throw Self.memberError(error)
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
      throw Self.memberError(error)
    }
  }

  public func removeMember(classID: Int, memberID: Int) async throws {
    do {
      _ = try await client.send(
        ClassMemberService.remove(classID: classID, memberID: memberID),
        as: PickeEmptyResponse.self
      )
    } catch {
      throw Self.memberError(error)
    }
  }

  private static func memberError(_ error: Error) -> ClassError {
    guard let networkError = error as? PickeNetworkError else { return ClassError.from(error) }
    guard case let .response(response) = networkError else { return ClassError.from(networkError) }
    return ClassErrorMapper.map(
      code: response.code,
      message: response.message,
      fallback: "멤버 요청을 처리하지 못했어요."
    )
  }
}
