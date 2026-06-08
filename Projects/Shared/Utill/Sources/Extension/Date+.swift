//
//  Date+.swift
//  Utill
//
//  날짜 포맷 유틸.
//

import Foundation

public extension Date {
  /// 지정 포맷 문자열로 변환 (ko_KR 고정).
  func toString(format: String) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = format
    return formatter.string(from: self)
  }

  /// `yyyy.M.d` 형식 (예: 2026.4.10).
  var yearMonthDayDot: String {
    toString(format: "yyyy.M.d")
  }
}

public extension Date? {
  /// nil 이면 빈 문자열.
  var yearMonthDayDot: String {
    self?.yearMonthDayDot ?? ""
  }
}
