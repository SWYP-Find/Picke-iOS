//
//  DefaultAttendanceRepositoryImpl.swift
//  DomainInterface
//
//  DI 미등록 시 폴백 — 네트워크를 타지 않고 빈 값을 돌려준다.
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
