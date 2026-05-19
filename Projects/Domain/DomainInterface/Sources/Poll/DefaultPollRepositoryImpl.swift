//
//  DefaultPollRepositoryImpl.swift
//  DomainInterface
//

import Entity
import Foundation

public struct DefaultPollRepositoryImpl: PollInterface {
  public init() {}

  public func fetchPoll(pollId _: Int) async throws -> PollDetail {
    .mock
  }
}
