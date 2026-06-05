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
}
