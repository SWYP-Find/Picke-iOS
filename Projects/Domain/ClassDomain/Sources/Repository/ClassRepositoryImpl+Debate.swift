//
//  ClassRepositoryImpl+Debate.swift
//  ClassDomain
//
//  Created by Picke on 10/26/26.
//

import APIEndpoint
import ClassDomainInterface
import Foundation
import PickeNetwork

extension ClassRepositoryImpl {
  public func fetchDebate(classID: Int) async throws -> ClassDebate {
    try await debate(.fetch(classID))
  }

  public func startDebate(classID: Int) async throws -> ClassDebate {
    try await debate(.start(classID))
  }

  public func retryDebate(classID: Int) async throws -> ClassDebate {
    try await debate(.retry(classID))
  }

  public func submitDebateReply(
    classID: Int,
    round: Int,
    content: String,
    requestKey: UUID
  ) async throws -> ClassDebate {
    try await debate(.submitReply(classID: classID, round: round, content: content, requestKey: requestKey))
  }

  private func debate(_ service: ClassDebateService) async throws -> ClassDebate {
    do {
      let payload = try await client.send(service, as: ClassDebateDTO.self)
      return try payload.toDomain()
    } catch let error as PickeNetworkError {
      if case let .response(response) = error {
        switch response.code {
        case "CLASS_404_DEBATE": throw ClassAIChatError.noSession
        case "CLASS_400_DEBATE_REPLY": throw ClassAIChatError.contentRejected
        case "CLASS_409_DEBATE_STATE", "CLASS_409_DEBATE_ROUND", "CLASS_409_DEBATE_RETRY":
          throw ClassAIChatError.temporarilyUnavailable
        default: throw ClassAIChatError.unexpectedFailure
        }
      }
      throw ClassAIChatError.temporarilyUnavailable
    }
  }

}
