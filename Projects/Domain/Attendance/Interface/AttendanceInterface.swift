//
//  AttendanceInterface.swift
//  DomainInterface
//

import Foundation
import WeaveDI

public protocol AttendanceInterface: Sendable {
  /// 오늘의 출석을 체크하고 포인트를 지급받는다. 하루 1회만 가능.
  func checkAttendance() async throws -> AttendanceCheckResult
  /// 이번 주(월~일) 요일별 출석 상태.
  func fetchWeeklyAttendance() async throws -> WeeklyAttendance
  /// 총 출석 일수·연속 출석·누적 포인트 통계.
  func fetchAttendanceSummary() async throws -> AttendanceSummary
}

public struct AttendanceRepositoryDependency: DependencyKey {
  public static var liveValue: AttendanceInterface {
    UnifiedDI.resolve(AttendanceInterface.self) ?? DefaultAttendanceRepositoryImpl()
  }

  public static var testValue: AttendanceInterface {
    UnifiedDI.resolve(AttendanceInterface.self) ?? DefaultAttendanceRepositoryImpl()
  }

  public static var previewValue: AttendanceInterface = liveValue
}

public extension DependencyValues {
  var attendanceRepository: AttendanceInterface {
    get { self[AttendanceRepositoryDependency.self] }
    set { self[AttendanceRepositoryDependency.self] = newValue }
  }
}

// UseCase 소비자용 별칭 — 인터페이스 강제(구현 모듈 import 불필요). pass-through 라 리포지토리 키로 해소.
public extension DependencyValues {
  var attendanceUseCase: AttendanceInterface {
    get { self[AttendanceRepositoryDependency.self] }
    set { self[AttendanceRepositoryDependency.self] = newValue }
  }
}
