//
//  WeeklyAttendanceDataDTO.swift
//  Model
//
//  GET /api/v1/attendance/weekly 응답 페이로드.
//

import Foundation

import Model

public struct WeeklyAttendanceDataDTO: Decodable {
  public let userTag: String?
  public let weekStartDate: String?
  public let consecutiveDays: Int?
  public let isStreakAchieved: Bool?
  public let weeklyAttendance: [AttendanceDayDTO]?
  public let streakRewardPoints: Int?

  enum CodingKeys: String, CodingKey {
    case userTag = "user_tag"
    case weekStartDate = "week_start_date"
    case consecutiveDays = "consecutive_days"
    case isStreakAchieved = "is_streak_achieved"
    case weeklyAttendance = "weekly_attendance"
    case streakRewardPoints = "streak_reward_points"
  }
}

public typealias WeeklyAttendanceResponseDTO = BaseResponseDTO<WeeklyAttendanceDataDTO>
