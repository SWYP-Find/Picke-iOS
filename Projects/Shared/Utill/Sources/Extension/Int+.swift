//
//  Int+DecimalFormat.swift
//  Utill
//
//  숫자 표시용 공통 포맷 (좋아요/조회수 등). Chat / Home / Auth / Hifi 등에서 공용 사용.
//

import Foundation

public extension Int {
  /// 천 단위 구분 콤마가 적용된 문자열. (예: 1340 → "1,340")
  var decimalFormatted: String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
  }

  /// 재생시간 초 → "X분 Y초".
  var durationText: String {
    let minutes = self / 60
    let seconds = self % 60
    if minutes > 0, seconds > 0 { return "\(minutes)분 \(seconds)초" }
    if minutes > 0 { return "\(minutes)분" }
    return "\(seconds)초"
  }

  /// 재생시간 초 → 반올림한 분 단위 텍스트. 1분 미만은 "1분".
  var roundedMinuteText: String {
    let roundedMinutes = Int((Double(self) / 60).rounded())
    let minutes = roundedMinutes < 1 ? 1 : roundedMinutes
    return "\(minutes)분"
  }
}
