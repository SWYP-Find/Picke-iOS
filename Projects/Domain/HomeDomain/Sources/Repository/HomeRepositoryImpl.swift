//
//  HomeRepositoryImpl.swift
//  Repository
//
//  Created by Wonji Suh on 5/16/26.
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

  public func fetchHome() async throws -> HomeBundle {
    let data = try await client.send(
      HomeService.home,
      as: HomeDataDTO.self
    )

    return data.toDomain()
  }
}
