//
//  ClassCreation.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/11/26.
//

import Foundation

public struct ClassCreation: Equatable, Sendable {
  public var name: String
  public var deadline: Date
  public var battleId: Int?
  public var topicVersionId: Int?
  public var allowsAnonymousOpinion: Bool
  public var requiresComment: Bool
  public var ownerParticipates: Bool
  public var ownerDisplayName: String?
  public var requestKey: String?

  public init(
    name: String,
    deadline: Date,
    battleId: Int,
    allowsAnonymousOpinion: Bool,
    requiresComment: Bool,
    ownerParticipates: Bool = false,
    ownerDisplayName: String? = nil,
    requestKey: String? = nil
  ) {
    self.name = name
    self.deadline = deadline
    self.battleId = battleId
    self.topicVersionId = nil
    self.allowsAnonymousOpinion = allowsAnonymousOpinion
    self.requiresComment = requiresComment
    self.ownerParticipates = ownerParticipates
    self.ownerDisplayName = ownerDisplayName
    self.requestKey = requestKey
  }

  public init(
    name: String,
    deadline: Date,
    topicVersionId: Int,
    allowsAnonymousOpinion: Bool,
    requiresComment: Bool,
    ownerParticipates: Bool = false,
    ownerDisplayName: String? = nil,
    requestKey: String? = nil
  ) {
    self.name = name
    self.deadline = deadline
    self.battleId = nil
    self.topicVersionId = topicVersionId
    self.allowsAnonymousOpinion = allowsAnonymousOpinion
    self.requiresComment = requiresComment
    self.ownerParticipates = ownerParticipates
    self.ownerDisplayName = ownerDisplayName
    self.requestKey = requestKey
  }
}
