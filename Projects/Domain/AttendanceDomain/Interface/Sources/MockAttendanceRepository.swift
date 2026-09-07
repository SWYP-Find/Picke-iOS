//
//  MockAttendanceRepository.swift
//  AttendanceDomainInterface
//

import Foundation

/// 계약을 만족하는 테스트/프리뷰용 더블.
/// 운영 구현은 `AttendanceRepositoryImpl`(Data) 이며 Interface 는 그 이름을 알지 않는다.
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
