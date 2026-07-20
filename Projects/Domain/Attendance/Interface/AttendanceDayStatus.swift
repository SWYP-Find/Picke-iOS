//
//  AttendanceDayStatus.swift
//  Entity
//
//  주간 출석 현황의 요일별 상태.
//

import Foundation

public enum AttendanceDayStatus: String, Equatable, Sendable {
  /// 출석 완료 — 채워진 원 + 획득 포인트.
  case attended = "ATTENDED"
  /// 결석 — 회색 원 + X.
  case missed = "MISSED"
  /// 아직 지나지 않은 날 — 점선 빈 원.
  case upcoming = "UPCOMING"

  /// 서버가 스펙에 없는 값을 보내도 앱이 깨지지 않도록 미도래로 폴백한다.
  public init(rawValue: String) {
    switch rawValue.uppercased() {
    case "ATTENDED": self = .attended
    case "MISSED", "ABSENT": self = .missed
    default: self = .upcoming
    }
  }
}
