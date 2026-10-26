//
//  ClassUseCaseImpl+Result.swift
//  ClassDomain
//
//  Created by Picke on 10/26/26.
//

import ClassDomainInterface
import Foundation

extension ClassUseCaseImpl {
  public func fetchResult(roomID: Int) async throws -> ClassResult {
    try await repository.fetchResult(roomID: roomID)
  }

  public func fetchPersonalResult(roomID: Int) async throws -> ClassAIPersonalFeedback {
    try await repository.fetchPersonalResult(roomID: roomID)
  }

  public func fetchInsight(roomID: Int) async throws -> ClassAIInsight {
    try await repository.fetchInsight(roomID: roomID)
  }

  public func retryInsight(roomID: Int) async throws {
    try await repository.retryInsight(roomID: roomID)
  }
}
