//
//  ServerDateParser.swift
//  PickeCoreUtility
//

import Foundation

/// 서버 시간 문자열 파서.
///
/// 서버가 `2026-05-22T13:28:16.697Z`(타임존 포함) 또는
/// `2026-05-22T13:28:16.921763` / `2026-05-22T13:28:16`(타임존 없는 LocalDateTime) 을
/// 섞어 내려주므로 ISO8601 을 먼저 시도하고 타임존 없는 포맷까지 폴백한다.
/// (기존엔 타임존 없는 문자열이 nil 로 파싱돼 모든 댓글이 "방금 전"으로 표시되던 버그)
public enum ServerDateParser {
  /// 타임존 없는 서버 시각은 서버 기준시(KST) 벽시계로 해석한다.
  private static let naiveFormats: [AppDateFormat] = [
    .serverDateTimeMicros,
    .serverDateTimeMillis,
    .serverDateTime,
  ]

  public static func parse(_ value: String) -> Date? {
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = isoFormatter.date(from: value) { return date }
    isoFormatter.formatOptions = [.withInternetDateTime]
    if let date = isoFormatter.date(from: value) { return date }

    // 마이크로초(`.921763`)는 Date 정밀도로 왕복이 안 되므로 왕복 검증 없이 파싱한다.
    for format in naiveFormats {
      if let date = AppDateFormatter[format].date(from: value) { return date }
    }
    return nil
  }
}
