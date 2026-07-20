//
//  AttendanceDayDTO.swift
//  Model
//
//  주간 출석 현황의 하루치 항목.
//

import Foundation

public struct AttendanceDayDTO: Decodable {
  public let day: String?
  public let date: String?
  public let status: String?
  public let points: Int?
}
