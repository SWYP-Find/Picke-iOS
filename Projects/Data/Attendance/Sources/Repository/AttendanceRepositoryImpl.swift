//
//  AttendanceRepositoryImpl.swift
//  Repository
//

import Foundation

import AttendanceDomainInterface
import Model
import Repository

import LogMacro

public final class AttendanceRepositoryImpl: AttendanceInterface, @unchecked Sendable {
  private let provider: any NetworkProviding<AttendanceService>

  public init(
    provider: any NetworkProviding<AttendanceService> = AlamofireNetworkProvider<AttendanceService>.authorized
  ) {
    self.provider = provider
  }

  public func checkAttendance() async throws -> AttendanceCheckResult {
    let dto: AttendanceCheckResponseDTO = try await provider.request(.check)

    guard let data = dto.data else {
      let message = dto.error?.message ?? "출석 체크 응답이 비어 있습니다"
      Log.error("[AttendanceRepositoryImpl] empty check payload: \(message)")
      throw AttendanceError.backendError(message)
    }

    return data.toDomain()
  }

  public func fetchWeeklyAttendance() async throws -> WeeklyAttendance {
    let dto: WeeklyAttendanceResponseDTO = try await provider.request(.weekly)

    guard let data = dto.data else {
      let message = dto.error?.message ?? "주간 출석 응답이 비어 있습니다"
      Log.error("[AttendanceRepositoryImpl] empty weekly payload: \(message)")
      throw AttendanceError.backendError(message)
    }

    return data.toDomain()
  }

  public func fetchAttendanceSummary() async throws -> AttendanceSummary {
    let dto: AttendanceSummaryResponseDTO = try await provider.request(.summary)

    guard let data = dto.data else {
      let message = dto.error?.message ?? "출석 통계 응답이 비어 있습니다"
      Log.error("[AttendanceRepositoryImpl] empty summary payload: \(message)")
      throw AttendanceError.backendError(message)
    }

    return data.toDomain()
  }
}
