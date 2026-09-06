//
//  AttendanceInterface.swift
//  AttendanceDomainInterface
//

import Foundation

import ComposableArchitecture

public protocol AttendanceInterface: Sendable {
  /// 오늘의 출석을 체크하고 포인트를 지급받는다. 하루 1회만 가능.
  func checkAttendance() async throws -> AttendanceCheckResult
  /// 이번 주(월~일) 요일별 출석 상태.
  func fetchWeeklyAttendance() async throws -> WeeklyAttendance
  /// 총 출석 일수·연속 출석·누적 포인트 통계.
  func fetchAttendanceSummary() async throws -> AttendanceSummary
}

// Interface 는 `testValue` 만 안다. `liveValue` 는 구현을 소유한 모듈이 등록한다
// (Repository → Data/Attendance, UseCase → Domain/Attendance/Sources).
// 등록이 빠지면 링크 단계에서 드러나므로 조용한 폴백이 생기지 않는다.

public enum AttendanceRepositoryDependency: TestDependencyKey {
  public static var testValue: AttendanceInterface { MockAttendanceRepository() }
}

public enum AttendanceUseCaseDependency: TestDependencyKey {
  public static var testValue: AttendanceInterface { MockAttendanceRepository() }
}

public extension DependencyValues {
  var attendanceRepository: AttendanceInterface {
    get { self[AttendanceRepositoryDependency.self] }
    set { self[AttendanceRepositoryDependency.self] = newValue }
  }
}

public extension DependencyValues {
  var attendanceUseCase: AttendanceInterface {
    get { self[AttendanceUseCaseDependency.self] }
    set { self[AttendanceUseCaseDependency.self] = newValue }
  }
}
