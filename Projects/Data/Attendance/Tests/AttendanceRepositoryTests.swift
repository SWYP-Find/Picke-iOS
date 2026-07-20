//
//  AttendanceRepositoryTests.swift
//  AttendanceDataTests
//

import Foundation
import Testing

import AttendanceDomainInterface

@testable import AttendanceData

@Suite("출석체크 리포지토리")
struct AttendanceRepositoryTests {
  @Test("출석 체크 응답을 도메인으로 매핑한다")
  func mapsCheckResponse() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "user_tag": "roy",
        "attended_at": "2026-07-20T13:45:02.608Z",
        "points_earned": 5,
        "streak_bonus_earned": false,
        "streak_bonus_points": 0,
        "consecutive_days": 2,
        "total_points": 120
      },
      "error": null
    }
    """
    let sut = AttendanceRepositoryImpl(
      provider: StubNetworkProvider<AttendanceService>(stubData: Data(json.utf8))
    )

    let result = try await sut.checkAttendance()

    #expect(result.pointsEarned == 5)
    #expect(result.consecutiveDays == 2)
    #expect(result.totalPoints == 120)
    #expect(result.streakBonusEarned == false)
    #expect(result.attendedAt != nil)
  }

  @Test("주간 출석 응답의 요일별 상태를 매핑한다")
  func mapsWeeklyResponse() async throws {
    let json = """
    {
      "statusCode": 200,
      "data": {
        "user_tag": "roy",
        "week_start_date": "2026-07-20",
        "consecutive_days": 2,
        "is_streak_achieved": false,
        "weekly_attendance": [
          { "day": "월", "date": "2026-07-20", "status": "ATTENDED", "points": 5 },
          { "day": "화", "date": "2026-07-21", "status": "MISSED", "points": 0 },
          { "day": "수", "date": "2026-07-22", "status": "UPCOMING", "points": 0 }
        ],
        "streak_reward_points": 7
      },
      "error": null
    }
    """
    let sut = AttendanceRepositoryImpl(
      provider: StubNetworkProvider<AttendanceService>(stubData: Data(json.utf8))
    )

    let weekly = try await sut.fetchWeeklyAttendance()

    #expect(weekly.days.count == 3)
    #expect(weekly.days[0].status == .attended)
    #expect(weekly.days[0].points == 5)
    #expect(weekly.days[1].status == .missed)
    #expect(weekly.days[2].status == .upcoming)
    #expect(weekly.streakRewardPoints == 7)
    // 결석이 섞여 있으므로 스트릭은 끊긴 것으로 본다.
    #expect(weekly.isStreakAlive == false)
  }

  @Test("data 가 비어 있으면 backendError 를 던진다")
  func throwsOnEmptyPayload() async {
    let json = """
    { "statusCode": 500, "data": null, "error": { "code": "E500", "message": "서버 오류" } }
    """
    let sut = AttendanceRepositoryImpl(
      provider: StubNetworkProvider<AttendanceService>(stubData: Data(json.utf8))
    )

    await #expect(throws: AttendanceError.backendError("서버 오류")) {
      try await sut.checkAttendance()
    }
  }
}
