//
//  AttendanceCheckDataDTO.swift
//  Model
//
//  POST /api/v1/attendance/check 응답 페이로드.
//

import Foundation

import Model

public struct AttendanceCheckDataDTO: Decodable {
  public let userTag: String?
  public let attendedAt: String?
  public let pointsEarned: Int?
  public let streakBonusEarned: Bool?
  public let streakBonusPoints: Int?
  public let consecutiveDays: Int?
  public let totalPoints: Int?

  enum CodingKeys: String, CodingKey {
    case userTag = "user_tag"
    case attendedAt = "attended_at"
    case pointsEarned = "points_earned"
    case streakBonusEarned = "streak_bonus_earned"
    case streakBonusPoints = "streak_bonus_points"
    case consecutiveDays = "consecutive_days"
    case totalPoints = "total_points"
  }
}

public typealias AttendanceCheckResponseDTO = BaseResponseDTO<AttendanceCheckDataDTO>
