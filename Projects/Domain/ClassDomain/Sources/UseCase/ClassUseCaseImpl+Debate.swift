//
//  ClassUseCaseImpl+Debate.swift
//  ClassDomain
//
//  Created by Picke on 10/26/26.
//

import ClassDomainInterface
import Foundation

extension ClassUseCaseImpl {
  public func fetchDebate(classID: Int) async throws -> ClassDebate {
    try await repository.fetchDebate(classID: classID)
  }

  public func startDebate(classID: Int) async throws -> ClassDebate {
    try await repository.startDebate(classID: classID)
  }

  public func submitDebateReply(
    classID: Int,
    round: Int,
    content: String,
    requestKey: UUID
  ) async throws -> ClassDebate {
    try await repository.submitDebateReply(
      classID: classID,
      round: round,
      content: content,
      requestKey: requestKey
    )
  }

  public func retryDebate(classID: Int) async throws -> ClassDebate {
    try await repository.retryDebate(classID: classID)
  }
}
