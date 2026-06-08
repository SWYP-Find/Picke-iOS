//
//  CreditHistory.swift
//  Entity
//
//  `GET /api/v1/me/credits/history` 응답 도메인 모델.
//  크레딧(포인트) 지급/사용 내역 + offset 기반 페이지네이션.
//

import Foundation

public struct CreditHistoryPage: Equatable {
  public let items: [CreditHistoryItem]
  public let nextOffset: Int
  public let hasNext: Bool

  public init(
    items: [CreditHistoryItem],
    nextOffset: Int,
    hasNext: Bool
  ) {
    self.items = items
    self.nextOffset = nextOffset
    self.hasNext = hasNext
  }
}

public struct CreditHistoryItem: Equatable, Identifiable {
  public let id: Int
  /// 크레딧 유형 코드 (예: `TODAY_CREDIT`).
  public let creditType: String
  /// 변동 포인트. 양수=적립, 음수=사용.
  public let amount: Int
  public let referenceId: Int?
  public let createdAt: Date?

  public init(
    id: Int,
    creditType: String,
    amount: Int,
    referenceId: Int?,
    createdAt: Date?
  ) {
    self.id = id
    self.creditType = creditType
    self.amount = amount
    self.referenceId = referenceId
    self.createdAt = createdAt
  }

  /// 적립 여부 (양수).
  public var isEarned: Bool { amount >= 0 }

  /// 금액 표시 (예: `+ 10P` / `- 5P`).
  public var amountText: String {
    "\(isEarned ? "+" : "-") \(abs(amount))P"
  }

  /// 적립/사용 라벨.
  public var statusText: String { isEarned ? "적립" : "사용" }

  /// 크레딧 유형 표시명.
  public var title: String {
    switch creditType {
    case "TODAY_CREDIT", "FREE_CREDIT", "SIGNUP_CREDIT":
      return "무료 충전"
    case "BATTLE_PARTICIPATION", "BATTLE_VOTE", "BATTLE":
      return "배틀 참여"
    default:
      return isEarned ? "포인트 적립" : "포인트 사용"
    }
  }
}
