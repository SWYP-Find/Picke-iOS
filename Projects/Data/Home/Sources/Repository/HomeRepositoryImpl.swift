//
//  HomeRepositoryImpl.swift
//  Repository
//
//  Created by Wonji Suh on 5/16/26.
//

import Foundation

import HomeDomainInterface
import Model
import Repository

import LogMacro
import AuthDomainInterface


public final class HomeRepositoryImpl: HomeInterface, @unchecked Sendable {
  private let provider: any NetworkProviding<HomeService>

  public init(
    provider: any NetworkProviding<HomeService> = AlamofireNetworkProvider<HomeService>.authorized
  ) {
    self.provider = provider
  }

  public func fetchHome() async throws -> HomeBundle {
    let dto: HomeResponseDTO = try await provider.request(.home)

    guard let data = dto.data else {
      let message = dto.error?.message ?? "홈 데이터 응답이 비어 있습니다"
      Log.error("[HomeRepositoryImpl] empty home payload: \(message)")
      throw AuthError.backendError(message)
    }

    return data.toDomain()
  }
}
