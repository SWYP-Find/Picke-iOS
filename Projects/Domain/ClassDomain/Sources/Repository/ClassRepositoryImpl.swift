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
    throw ClassError.network(Self.unavailableMessage)
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

  public func createClass(_: ClassCreation) async throws -> ClassRoom {
    throw ClassError.network(Self.unavailableMessage)
  }

  public func fetchClass(joinCode _: String) async throws -> ClassRoom {
    throw ClassError.network(Self.unavailableMessage)
  }

  public func joinClass(joinCode _: String, nickname _: String) async throws -> ClassRoom {
    throw ClassError.network(Self.unavailableMessage)
  }

  public func updateDeadline(id _: Int, deadline _: Date) async throws -> ClassRoom {
    throw ClassError.network(Self.unavailableMessage)
  }

  public func deleteClass(id _: Int) async throws {
    throw ClassError.network(Self.unavailableMessage)
  }

  public func leaveClass(id _: Int) async throws {
    throw ClassError.network(Self.unavailableMessage)
  }

  public func fetchReport(roomID _: Int) async throws -> ClassReport? {
    throw ClassError.network(Self.unavailableMessage)
  }

  public func fetchOwnerDashboard(roomID _: Int) async throws -> ClassOwnerDashboardData? {
    throw ClassError.network(Self.unavailableMessage)
  }
}
