//
//  AttendanceDomainTests.swift
//  AttendanceDomainTests
//

import Testing

@testable import AttendanceDomainInterface

@Suite("출석체크 도메인")
struct AttendanceDomainTests {
  @Test("서버가 모르는 status 값을 보내면 미도래(upcoming)로 폴백한다")
  func unknownStatusFallsBackToUpcoming() {
    #expect(AttendanceDayStatus(rawValue: "ATTENDED") == .attended)
    #expect(AttendanceDayStatus(rawValue: "MISSED") == .missed)
    #expect(AttendanceDayStatus(rawValue: "천만에요") == .upcoming)
  }

  @Test("결석이 하나라도 있으면 스트릭이 끊긴 것으로 본다")
  func streakBreaksOnAnyMissedDay() {
    let missed = WeeklyAttendance(
      weekStartDate: "2026-07-20",
      consecutiveDays: 1,
      isStreakAchieved: false,
      days: [
        AttendanceDay(day: "월", date: "2026-07-20", status: .missed, points: 0),
        AttendanceDay(day: "화", date: "2026-07-21", status: .attended, points: 5),
      ],
      streakRewardPoints: 7
    )
    #expect(missed.isStreakAlive == false)

    let alive = WeeklyAttendance(
      weekStartDate: "2026-07-20",
      consecutiveDays: 2,
      isStreakAchieved: false,
      days: [
        AttendanceDay(day: "월", date: "2026-07-20", status: .attended, points: 5),
        AttendanceDay(day: "화", date: "2026-07-21", status: .upcoming, points: 0),
      ],
      streakRewardPoints: 7
    )
    #expect(alive.isStreakAlive == true)
  }
}
