//
//  DefaultAttendanceRepositoryImpl.swift
//  DomainInterface
//

import Foundation

public struct DefaultAttendanceRepositoryImpl: AttendanceInterface {
  public init() {}

  public func checkAttendance() async throws -> AttendanceCheckResult {
    .empty
  }

  public func fetchWeeklyAttendance() async throws -> WeeklyAttendance {
    .empty
  }

  public func fetchAttendanceSummary() async throws -> AttendanceSummary {
    .empty
  }
}
