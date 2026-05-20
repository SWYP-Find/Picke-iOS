//
//  PollInterface.swift
//  DomainInterface
//

import Entity
import Foundation
import WeaveDI

public protocol PollInterface: Sendable {
  func fetchPoll(pollId: Int) async throws -> PollDetail
}

public struct PollRepositoryDependency: DependencyKey {
  public static var liveValue: PollInterface {
    return UnifiedDI.resolve(PollInterface.self) ?? DefaultPollRepositoryImpl()
  }

  public static var testValue: PollInterface {
    return UnifiedDI.resolve(PollInterface.self) ?? DefaultPollRepositoryImpl()
  }

  public static var previewValue: PollInterface = liveValue
}

public extension DependencyValues {
  var pollRepository: PollInterface {
    get { self[PollRepositoryDependency.self] }
    set { self[PollRepositoryDependency.self] = newValue }
  }
}
