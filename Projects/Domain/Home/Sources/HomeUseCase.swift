//
//  HomeUseCase.swift
//  UseCase
//

import Foundation

import HomeDomainInterface

import ComposableArchitecture

public struct HomeUseCaseImpl: HomeInterface {
  @Dependency(\.homeRepository) private var homeRepository

  public init() {}

  public func fetchHome() async throws -> HomeBundle {
    return try await homeRepository.fetchHome()
  }
}

extension HomeUseCaseImpl: DependencyKey {
  public static var liveValue = HomeUseCaseImpl()
  public static var testValue = HomeUseCaseImpl()
  public static var previewValue = HomeUseCaseImpl()
}

public extension DependencyValues {
  var homeUseCase: HomeUseCaseImpl {
    get { self[HomeUseCaseImpl.self] }
    set { self[HomeUseCaseImpl.self] = newValue }
  }
}
