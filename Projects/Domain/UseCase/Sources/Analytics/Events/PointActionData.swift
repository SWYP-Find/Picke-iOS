//
//  PointActionData.swift
//  UseCase
//

import Foundation

public enum PointActionType: String, Sendable {
  case attendanceEarn = "attendance_earn"
  case adEarn = "ad_earn"
  case battleSpend = "battle_spend"
}

public struct PointActionData: Sendable {
  public let type: PointActionType
  public let amount: Int
  public let balance: Int?

  public init(type: PointActionType, amount: Int, balance: Int? = nil) {
    self.type = type
    self.amount = amount
    self.balance = balance
  }
}
