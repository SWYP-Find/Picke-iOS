//
//  AttendanceDataDTO+.swift
//  Model
//
//  출석체크 DTO → 도메인 엔티티 매핑.
//

import Foundation

import AttendanceDomainInterface

public extension AttendanceCheckDataDTO {
  func toDomain() -> AttendanceCheckResult {
    AttendanceCheckResult(
      attendedAt: attendedAt.flatMap(AttendanceDateParser.date(from:)),
      pointsEarned: pointsEarned ?? 0,
      streakBonusEarned: streakBonusEarned ?? false,
      streakBonusPoints: streakBonusPoints ?? 0,
      consecutiveDays: consecutiveDays ?? 0,
      totalPoints: totalPoints ?? 0
    )
  }
}

public extension WeeklyAttendanceDataDTO {
  func toDomain() -> WeeklyAttendance {
    WeeklyAttendance(
      weekStartDate: weekStartDate ?? "",
      consecutiveDays: consecutiveDays ?? 0,
      isStreakAchieved: isStreakAchieved ?? false,
      days: (weeklyAttendance ?? []).map { $0.toDomain() },
      streakRewardPoints: streakRewardPoints ?? 0
    )
  }
}

public extension AttendanceDayDTO {
  func toDomain() -> AttendanceDay {
    AttendanceDay(
      day: day ?? "",
      date: date ?? "",
      status: AttendanceDayStatus(rawValue: status ?? ""),
      points: points ?? 0
    )
  }
}

public extension AttendanceSummaryDataDTO {
  func toDomain() -> AttendanceSummary {
    AttendanceSummary(
      totalAttendedDays: totalAttendedDays ?? 0,
      currentConsecutiveDays: currentConsecutiveDays ?? 0,
      maxConsecutiveDays: maxConsecutiveDays ?? 0,
      totalPointsFromAttendance: totalPointsFromAttendance ?? 0,
      lastAttendedAt: lastAttendedAt.flatMap(AttendanceDateParser.date(from:))
    )
  }
}

/// 출석 API 의 시각 필드는 `2026-07-20T13:45:02.608Z` 형태(ISO8601 + 소수점 초)로 내려온다.
/// 서버가 소수점을 생략하는 케이스도 있어 두 포맷을 순서대로 시도한다.
enum AttendanceDateParser {
  private static let withFractionalSeconds: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  private static let plain: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
  }()

  static func date(from value: String) -> Date? {
    withFractionalSeconds.date(from: value) ?? plain.date(from: value)
  }
}
