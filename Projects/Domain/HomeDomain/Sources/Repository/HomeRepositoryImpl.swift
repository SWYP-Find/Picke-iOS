//
//  HomeRepositoryImpl.swift
//  HomeDomain
//
//  Created by Picke on 5/16/26.
//

import Foundation

import Dependencies

import APIEndpoint
import HomeDomainInterface
import PickeNetwork

import AuthDomainInterface

public final class HomeRepositoryImpl: HomeInterface, @unchecked Sendable {
  @Dependency(\.networkClient) private var client

  public init() {}

  /// Android `HomeViewModel` 처럼 홈과 주간 베스트 관점을 함께 받아 Best 댓글을 상위 3개로 채운다.
  /// 주간 베스트는 운영 서버에 아직 없을 수 있어 실패하면 Best 댓글 섹션만 비운다.
  public func fetchHome() async throws -> HomeBundle {
    async let home = client.send(
      HomeService.home,
      as: HomeDataDTO.self
    )
    async let weeklyBest = try? client.send(
      PerspectiveService.weeklyBest,
      as: WeeklyBestPerspectiveDataDTO.self
    )

    let bestComments = await weeklyBest?.items
      .prefix(Self.bestCommentCount)
      .map { $0.toDomain() } ?? []
    return try await home.toDomain(bestComments: bestComments)
  }

  private static let bestCommentCount = 3
}
