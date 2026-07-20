//
//  AttendanceCheckResult.swift
//  Entity
//
//  오늘의 출석 체크 결과 — POST /attendance/check 응답.
//

import Foundation

public struct AttendanceCheckResult: Equatable, Sendable {
  public let attendedAt: Date?
  public let pointsEarned: Int
  public let streakBonusEarned: Bool
  public let streakBonusPoints: Int
  public let consecutiveDays: Int
  public let totalPoints: Int

  public init(
    attendedAt: Date?,
    pointsEarned: Int,
    streakBonusEarned: Bool,
    streakBonusPoints: Int,
    consecutiveDays: Int,
    totalPoints: Int
  ) {
    self.attendedAt = attendedAt
    self.pointsEarned = pointsEarned
    self.streakBonusEarned = streakBonusEarned
    self.streakBonusPoints = streakBonusPoints
    self.consecutiveDays = consecutiveDays
    self.totalPoints = totalPoints
  }

  public static let empty = AttendanceCheckResult(
    attendedAt: nil,
    pointsEarned: 0,
    streakBonusEarned: false,
    streakBonusPoints: 0,
    consecutiveDays: 0,
    totalPoints: 0
  )
}
