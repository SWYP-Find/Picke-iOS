//
//  WeeklyAttendance.swift
//  Entity
//
//  이번 주(월~일) 출석 현황.
//

import Foundation

public struct WeeklyAttendance: Equatable, Sendable {
  public let weekStartDate: String
  public let consecutiveDays: Int
  /// 이번 주 7일 연속 출석 달성 여부.
  public let isStreakAchieved: Bool
  public let days: [AttendanceDay]
  /// 7일 연속 달성 시 지급되는 보너스 포인트.
  public let streakRewardPoints: Int

  public init(
    weekStartDate: String,
    consecutiveDays: Int,
    isStreakAchieved: Bool,
    days: [AttendanceDay],
    streakRewardPoints: Int
  ) {
    self.weekStartDate = weekStartDate
    self.consecutiveDays = consecutiveDays
    self.isStreakAchieved = isStreakAchieved
    self.days = days
    self.streakRewardPoints = streakRewardPoints
  }

  public static let empty = WeeklyAttendance(
    weekStartDate: "",
    consecutiveDays: 0,
    isStreakAchieved: false,
    days: [],
    streakRewardPoints: 0
  )

  /// 스트릭이 이미 끊겼으면 마지막 날 보상 아이콘을 감춘다(디자인 2안).
  public var isStreakAlive: Bool {
    !days.contains { $0.status == .missed }
  }
}
