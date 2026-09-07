//
//  AttendanceRepositoryImpl.swift
//  Repository
//

import Foundation

import Dependencies

import APIEndpoint
import AttendanceDomainInterface
import PickeNetwork

import LogMacro

public final class AttendanceRepositoryImpl: AttendanceInterface, @unchecked Sendable {
  @Dependency(\.networkClient) private var client

  public init() {}

  public func checkAttendance() async throws -> AttendanceCheckResult {
    let data = try await client.send(
      AttendanceService.check,
      as: AttendanceCheckDataDTO.self
    )

    return data.toDomain()
  }

  public func fetchWeeklyAttendance() async throws -> WeeklyAttendance {
    let data = try await client.send(
      AttendanceService.weekly,
      as: WeeklyAttendanceDataDTO.self
    )

    return data.toDomain()
  }

  public func fetchAttendanceSummary() async throws -> AttendanceSummary {
    let data = try await client.send(
      AttendanceService.summary,
      as: AttendanceSummaryDataDTO.self
    )

    return data.toDomain()
  }
}
