//
//  ClassRepositoryImpl.swift
//  ClassDomain
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import Dependencies
import Foundation
import PickeNetwork

public struct ClassRepositoryImpl: ClassInterface {
  private static let unavailableMessage = "클래스 서버 API가 연결되지 않았습니다."
  @Dependency(\.networkClient) private var client

  public init() {}

  public func fetchMyClasses() async throws -> [ClassRoom] {
    do {
      let data = try await client.send(ClassroomService.myClasses, as: [ClassListItemDTO].self)
      return try data.map { try $0.toDomain() }
    } catch {
      throw Self.classError(error)
    }
  }

  public func fetchRecommendedBattles(filter: ClassTopicFilter) async throws -> [ClassBattleSummary] {
    guard (1 ... 3).contains(filter.categories.count), filter.keyword.count <= 50 else {
      throw ClassError.unknown("추천 조건을 확인해 주세요.")
    }
    do {
      let data = try await client.send(
        ClassBattleRecommendationService.recommendations(filter: filter),
        as: ClassBattleRecommendationDataDTO.self
      )
      return try data.items.map { try $0.toDomain() }
    } catch let error as PickeNetworkError {
      if case let .response(response) = error {
        throw ClassError.network(response.message ?? "배틀 추천을 불러오지 못했습니다.")
      }
      throw ClassError.from(error)
    }
  }

  public func createClass(_ creation: ClassCreation) async throws -> ClassRoom {
    do {
      let data = try await client.send(ClassroomService.create(creation), as: ClassDetailDataDTO.self)
      return try data.toDomain()
    } catch {
      throw Self.classError(error)
    }
  }

  public func fetchClass(id: Int) async throws -> ClassRoom {
    do {
      let data = try await client.send(ClassroomService.detail(id), as: ClassDetailDataDTO.self)
      return try data.toDomain()
    } catch {
      throw Self.classError(error)
    }
  }

  public func fetchClass(joinCode _: String) async throws -> ClassRoom {
    throw ClassError.unknown("참여 미리보기는 클래스 상세를 제공하지 않습니다.")
  }

  public func fetchClassPreview(joinCode: String) async throws -> ClassJoinPreview {
    do {
      let data = try await client.send(
        ClassroomService.joinPreview(joinCode),
        as: ClassJoinPreviewDataDTO.self
      )
      return try data.toDomain()
    } catch {
      throw Self.classError(error)
    }
  }

  public func joinClass(joinCode: String, nickname: String) async throws -> ClassRoom {
    do {
      let data = try await client.send(
        ClassroomService.join(code: joinCode, nickname: nickname),
        as: ClassDetailDataDTO.self
      )
      return try data.toDomain()
    } catch {
      throw Self.classError(error)
    }
  }

  public func updateDeadline(id: Int, deadline: Date) async throws -> ClassRoom {
    do {
      _ = try await client.send(
        ClassroomService.updateDeadline(id: id, deadline: deadline),
        as: PickeEmptyResponse.self
      )
      let data = try await client.send(ClassroomService.detail(id), as: ClassDetailDataDTO.self)
      return try data.toDomain()
    } catch {
      throw Self.classError(error)
    }
  }

  public func deleteClass(id: Int) async throws {
    do {
      _ = try await client.send(ClassroomService.delete(id), as: PickeEmptyResponse.self)
    } catch {
      throw Self.classError(error)
    }
  }

  public func leaveClass(id: Int) async throws {
    do {
      _ = try await client.send(ClassroomService.leave(id), as: PickeEmptyResponse.self)
    } catch {
      throw Self.classError(error)
    }
  }

  public func fetchReport(roomID _: Int) async throws -> ClassReport? {
    throw ClassError.network(Self.unavailableMessage)
  }

  public func fetchOwnerDashboard(roomID _: Int) async throws -> ClassOwnerDashboardData? {
    throw ClassError.network(Self.unavailableMessage)
  }

  private static func classError(_ error: Error) -> ClassError {
    guard let networkError = error as? PickeNetworkError else { return ClassError.from(error) }
    guard case let .response(response) = networkError else { return ClassError.from(networkError) }
    return ClassErrorMapper.map(
      code: response.code,
      message: response.message,
      fallback: "클래스 요청을 처리하지 못했습니다."
    )
  }
}
