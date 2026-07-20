//
//  AttendanceDay.swift
//  Entity
//
//  주간 출석 현황의 하루치 셀.
//

import Foundation

public struct AttendanceDay: Equatable, Identifiable, Sendable {
  /// 요일 표기(월~일) — 서버가 내려주는 값을 그대로 노출한다.
  public let day: String
  public let date: String
  public let status: AttendanceDayStatus
  public let points: Int

  public var id: String { date }

  public init(
    day: String,
    date: String,
    status: AttendanceDayStatus,
    points: Int
  ) {
    self.day = day
    self.date = date
    self.status = status
    self.points = points
  }
}
