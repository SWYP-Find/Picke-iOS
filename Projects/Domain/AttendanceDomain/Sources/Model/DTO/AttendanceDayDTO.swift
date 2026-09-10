//
//  AttendanceDayDTO.swift
//  AttendanceDomain
//

import Foundation

public struct AttendanceDayDTO: Decodable {
  public let day: String?
  public let date: String?
  public let status: String?
  public let points: Int?
}
