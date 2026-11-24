//
//  ClassDeadlineWheelTests.swift
//  ClassTests
//
//  Created by Picke on 10/15/26.
//

@testable import Class
import Foundation
import PickeCoreUtility
import Testing

struct ClassDeadlineWheelTests {
  @Test
  func 같은_행을_선택하면_초를_포함한_원본을_보존한다() throws {
    let selected = try date("2026-10-15 14:30:40")
    let minimum = try date("2026-10-14 00:00:00")
    let wheel = ClassDeadlineWheel(selection: selected, minimumDate: minimum)
    #expect(wheel.selecting(day: ClassDeadlineWheel.dayID(selected), from: selected, minimumDate: minimum) == selected)
    #expect(wheel.selecting(hour: 14, from: selected, minimumDate: minimum) == selected)
    #expect(wheel.selecting(minute: 30, from: selected, minimumDate: minimum) == selected)
  }

  @Test
  func 자정으로_시를_변경해도_선택한_날짜를_유지한다() throws {
    let selected = try date("2026-12-31 23:30:40")
    let minimum = try date("2026-12-30 00:00:00")
    let wheel = ClassDeadlineWheel(selection: selected, minimumDate: minimum)
    #expect(try wheel.selecting(hour: 0, from: selected, minimumDate: minimum) == date("2026-12-31 00:30:00"))
  }

  private func date(_ value: String) throws -> Date {
    try #require(value.date(as: .dateTime))
  }

  @Test
  func 월말과_윤년의_날짜_선택은_시분을_보존한다() throws {
    let selected = try date("2028-02-28 23:59:35")
    let minimum = try date("2028-01-01 00:00:00")
    let wheel = ClassDeadlineWheel(selection: selected, minimumDate: minimum)
    let next = wheel.selecting(
      day: ClassDeadlineWheel.dayID(selected) + 1,
      from: selected,
      minimumDate: minimum
    )
    #expect(try next == date("2028-02-29 23:59:00"))
    #expect(try wheel.selecting(day: ClassDeadlineWheel.dayID(next) + 1, from: next, minimumDate: minimum)
      == date("2028-03-01 23:59:00"))
  }

  @Test
  func 연도가_바뀌어도_날짜_ID는_하루씩_증가한다() throws {
    let last = try date("2026-12-31 17:30:00")
    let first = try date("2027-01-01 17:30:00")
    #expect(ClassDeadlineWheel.dayID(first) == ClassDeadlineWheel.dayID(last) + 1)
    #expect(try ClassDeadlineWheel.date(for: ClassDeadlineWheel.dayID(first)) == date("2027-01-01 00:00:00"))
  }

  @Test
  func 최소시각_변경은_ID를_바꾸지_않고_선택값만_제한한다() throws {
    let selected = try date("2026-10-15 14:30:00")
    let wheel = ClassDeadlineWheel(selection: selected, minimumDate: selected)
    let later = try date("2026-10-16 00:00:01")
    let newWheel = ClassDeadlineWheel(selection: selected, minimumDate: later)
    #expect(wheel.days(including: selected).lowerBound == newWheel.days(including: selected).lowerBound)
    #expect(wheel.selecting(hour: 1, from: selected, minimumDate: later) == later)
  }

  @Test
  func 상한은_선택을_바꿔도_늘어나지_않고_무기한을_제외한다() throws {
    let selected = try date("2026-10-15 14:30:00")
    let wheel = ClassDeadlineWheel(selection: selected, minimumDate: selected)
    let maximum = wheel.maximumDate
    let result = wheel.selecting(day: ClassDeadlineWheel.dayID(maximum) + 1, from: maximum, minimumDate: selected)
    #expect(result == maximum)
    #expect(wheel.maximumDate == maximum)
    #expect(wheel.maximumDate < .distantFuture)
    #expect(wheel.days(including: result).count < 3700)
    let far = ClassDeadlineWheel(selection: .distantFuture, minimumDate: selected)
    #expect(far.maximumDate < .distantFuture)
  }

  @Test
  func 시와_분을_선택하면_나머지_달력값을_보존한다() throws {
    let selected = try date("2026-10-15 14:30:40")
    let minimum = try date("2026-10-14 00:00:00")
    let wheel = ClassDeadlineWheel(selection: selected, minimumDate: minimum)
    #expect(try wheel.selecting(hour: 23, from: selected, minimumDate: minimum) == date("2026-10-15 23:30:00"))
    #expect(try wheel.selecting(minute: 0, from: selected, minimumDate: minimum) == date("2026-10-15 14:00:00"))
  }
}
