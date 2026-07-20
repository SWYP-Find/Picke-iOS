//
//  AttendanceUseCase.swift
//  AttendanceDomain
//
//  출석체크 pass-through UseCase — 리포지토리를 그대로 위임한다.
//

import Foundation

import AttendanceDomainInterface
import ComposableArchitecture

public struct AttendanceUseCaseImpl: AttendanceInterface {
  @Dependency(\.attendanceRepository) private var attendanceRepository

  public init() {}

  public func checkAttendance() async throws -> AttendanceCheckResult {
    try await attendanceRepository.checkAttendance()
  }

  public func fetchWeeklyAttendance() async throws -> WeeklyAttendance {
    try await attendanceRepository.fetchWeeklyAttendance()
  }

  public func fetchAttendanceSummary() async throws -> AttendanceSummary {
    try await attendanceRepository.fetchAttendanceSummary()
  }
}
