//
//  AttendanceSummary.swift
//  Entity
//

import Foundation

public struct AttendanceSummary: Equatable, Sendable {
  public let totalAttendedDays: Int
  public let currentConsecutiveDays: Int
  public let maxConsecutiveDays: Int
  public let totalPointsFromAttendance: Int
  public let lastAttendedAt: Date?

  public init(
    totalAttendedDays: Int,
    currentConsecutiveDays: Int,
    maxConsecutiveDays: Int,
    totalPointsFromAttendance: Int,
    lastAttendedAt: Date?
  ) {
    self.totalAttendedDays = totalAttendedDays
    self.currentConsecutiveDays = currentConsecutiveDays
    self.maxConsecutiveDays = maxConsecutiveDays
    self.totalPointsFromAttendance = totalPointsFromAttendance
    self.lastAttendedAt = lastAttendedAt
  }

  public static let empty = AttendanceSummary(
    totalAttendedDays: 0,
    currentConsecutiveDays: 0,
    maxConsecutiveDays: 0,
    totalPointsFromAttendance: 0,
    lastAttendedAt: nil
  )
}
