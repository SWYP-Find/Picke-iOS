//
//  ServerNaiveDateParser.swift
//  Model
//
//  타임존 없이 내려오는 서버 시각(예: "2026-07-12T21:26:26.921763")을 파싱한다.
//  ISO8601DateFormatter 는 타임존 지정자(Z/오프셋)가 필수라 이런 값은 파싱하지 못하므로,
//  KST 벽시계 시각으로 해석한다(표시도 기기 로컬 KST 이므로 서버가 준 날짜와 일치).
//

import Foundation

public enum ServerNaiveDateParser {
  private static let formats = [
    "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
    "yyyy-MM-dd'T'HH:mm:ss",
  ]

  public static func date(from value: String) -> Date? {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
    for format in formats {
      formatter.dateFormat = format
      if let date = formatter.date(from: value) { return date }
    }
    return nil
  }
}
