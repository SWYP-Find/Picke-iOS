//
//  ClassParticipationMetrics.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/11/26.
//

public struct ClassParticipationMetrics: Equatable, Sendable {
  public let commentAuthorCount: Int
  public let optionAVoteCount: Int
  public let optionBVoteCount: Int

  public init(
    commentAuthorCount: Int,
    optionAVoteCount: Int,
    optionBVoteCount: Int
  ) {
    self.commentAuthorCount = commentAuthorCount
    self.optionAVoteCount = optionAVoteCount
    self.optionBVoteCount = optionBVoteCount
  }
}
