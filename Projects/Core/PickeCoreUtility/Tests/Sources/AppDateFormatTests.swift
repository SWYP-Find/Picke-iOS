//
//  AppDateFormatTests.swift
//  PickeCoreUtilityTests
//
//  Created by Picke on 10/12/26.
//

import Foundation
import PickeCoreUtility
import Testing

struct AppDateFormatTests {
  @Test
  func 선택한_마감일은_서울_시간으로_표시한다() throws {
    let instant = try #require(ISO8601DateFormatter().date(from: "2026-10-12T05:30:00Z"))
    #expect(instant.formatted(.pickerDay) == "10월 12일 월")
    #expect(instant.formatted(.pickerDay, timeZone: AppDateFormat.timeZone) == "10월 12일 월")
    #expect(instant.formatted(.fullKoreanDateTime) == "2026년 10월 12일 14:30")
    #expect(instant.formatted(.dottedDateTimeWithWeekday) == "2026. 10. 12. 월요일 14:30")
    let text = instant.formatted(.dottedDateTimeWithWeekday)
    #expect(text.date(as: .dottedDateTimeWithWeekday, timeZone: AppDateFormat.timeZone) == instant)
  }

  @Test
  func 날짜_선택기의_달력과_시간대는_표시_포맷과_같다() throws {
    let calendar = AppDateFormat.calendar
    #expect(calendar.identifier == .gregorian)
    #expect(calendar.timeZone == AppDateFormat.timeZone)
    #expect(calendar.timeZone.identifier == "Asia/Seoul")

    let selected = try #require(calendar.date(from: DateComponents(
      year: 2026,
      month: 10,
      day: 12,
      hour: 14,
      minute: 30
    )))
    var otherCalendar = Calendar(identifier: .gregorian)
    otherCalendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
    #expect(otherCalendar.component(.hour, from: selected) != 14)
    #expect(selected.formatted(.fullKoreanDateTime) == "2026년 10월 12일 14:30")
    #expect("2026년 10월 12일 14:30".date(as: .fullKoreanDateTime) == selected)
  }
}
