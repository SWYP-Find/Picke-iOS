//
//  AttendanceDayDTO.swift
//  AttendanceDomain
//
//  Created by Picke on 10/11/26.
//

import Foundation

public struct AttendanceDayDTO: Decodable {
  public let day: String?
  public let date: String?
  public let status: String?
  public let points: Int?
}
