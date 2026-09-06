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

