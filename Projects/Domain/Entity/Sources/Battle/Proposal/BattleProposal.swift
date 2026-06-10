//
//  BattleProposal.swift
//  Entity
//
//  배틀 주제 제안 결과 (POST /api/v1/battles/proposals 응답).
//

import Foundation

public struct BattleProposal: Equatable, Identifiable {
  public let id: Int
  public let userId: Int
  public let nickname: String
  public let category: String
  public let topic: String
  public let positionA: String
  public let positionB: String
  public let description: String
  /// 제안 상태 (예: `PENDING`).
  public let status: String
  public let createdAt: Date?

  public init(
    id: Int,
    userId: Int,
    nickname: String,
    category: String,
    topic: String,
    positionA: String,
    positionB: String,
    description: String,
    status: String,
    createdAt: Date?
  ) {
    self.id = id
    self.userId = userId
    self.nickname = nickname
    self.category = category
    self.topic = topic
    self.positionA = positionA
    self.positionB = positionB
    self.description = description
    self.status = status
    self.createdAt = createdAt
  }
}
