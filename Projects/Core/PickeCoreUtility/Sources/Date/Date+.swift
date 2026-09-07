//
//  Date+.swift
//  PickeCoreUtility
//

import Foundation

public extension Date {
  /// `yyyy.M.d` 형식 (예: 2026.4.10).
  var yearMonthDayDot: String {
    formatted(.yearMonthDayDotShort)
  }

  /// 한국어 상대 시간 (방금 전 / N분 전 / N시간 전 / N일 전).
  var relativeKoreanString: String {
    let interval = Date().timeIntervalSince(self)
    if interval < 60 { return "방금 전" }
    if interval < 3600 { return "\(Int(interval / 60))분 전" }
    if interval < 86400 { return "\(Int(interval / 3600))시간 전" }
    return "\(Int(interval / 86400))일 전"
  }
}

public extension Date? {
  /// nil 이면 빈 문자열.
  var yearMonthDayDot: String {
    self?.yearMonthDayDot ?? ""
  }

  /// nil 이면 빈 문자열.
  var relativeKoreanString: String {
    self?.relativeKoreanString ?? ""
  }
}
