//
//  MockAttendanceRepository.swift
//  AttendanceDomainInterface
//

import Foundation

/// 계약을 만족하는 테스트/프리뷰용 더블.
public struct MockAttendanceRepository: AttendanceInterface {
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
