//
//  ProfileUseCase.swift
//  UseCase
//

import Foundation

import DomainInterface
import Entity

import ComposableArchitecture

public struct ProfileUseCaseImpl: ProfileInterface {
  @Dependency(\.profileRepository) private var profileRepository

  public init() {}

  public func fetchMyPage() async throws -> MyPage {
    return try await profileRepository.fetchMyPage()
  }

  public func fetchCreditHistory(
    offset: Int,
    size: Int
  ) async throws -> CreditHistoryPage {
    return try await profileRepository.fetchCreditHistory(offset: offset, size: size)
  }
}

extension ProfileUseCaseImpl: DependencyKey {
  public static var liveValue = ProfileUseCaseImpl()
  public static var testValue = ProfileUseCaseImpl()
  public static var previewValue = ProfileUseCaseImpl()
}

public extension DependencyValues {
  var profileUseCase: ProfileUseCaseImpl {
    get { self[ProfileUseCaseImpl.self] }
    set { self[ProfileUseCaseImpl.self] = newValue }
  }
}
