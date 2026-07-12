//
//  MockHomeRepository.swift
//  DomainInterface
//
//  Created by Wonji Suh on 5/16/26.
//

import Entity
import Foundation

import DomainInterface

public final class MockHomeRepository: HomeInterface, @unchecked Sendable {
  public enum Configuration {
    case success(HomeBundle)
    case failure(Error)
    case empty
  }

  private let configuration: Configuration
  public private(set) var fetchCallCount = 0

  public init(configuration: Configuration = .success(.mock)) {
    self.configuration = configuration
  }

  public func fetchHome() async throws -> HomeBundle {
    fetchCallCount += 1
    try await Task.sleep(for: .milliseconds(10))

    switch configuration {
    case let .success(bundle):
      return bundle
    case let .failure(error):
      throw error
    case .empty:
      return HomeBundle(
        newNotice: false,
        heroes: [], hotBattles: [], bestBattles: [],
        quizzes: [], votes: [], newBattles: []
      )
    }
  }
}
