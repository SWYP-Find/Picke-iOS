//
//  AttendanceSummaryDataDTO.swift
//  Model
//

import Foundation

import Model

public struct AttendanceSummaryDataDTO: Decodable {
  public let userTag: String?
  public let totalAttendedDays: Int?
  public let currentConsecutiveDays: Int?
  public let maxConsecutiveDays: Int?
  public let totalPointsFromAttendance: Int?
  public let lastAttendedAt: String?

  enum CodingKeys: String, CodingKey {
    case userTag = "user_tag"
    case totalAttendedDays = "total_attended_days"
    case currentConsecutiveDays = "current_consecutive_days"
    case maxConsecutiveDays = "max_consecutive_days"
    case totalPointsFromAttendance = "total_points_from_attendance"
    case lastAttendedAt = "last_attended_at"
  }
}

public typealias AttendanceSummaryResponseDTO = BaseResponseDTO<AttendanceSummaryDataDTO>
