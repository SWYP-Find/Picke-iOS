//
//  ClassDeadlineWheel.swift
//  Class
//
//  Created by Picke on 10/15/26.
//

import Foundation
import PickeCoreUtility

/// Calendar arithmetic for the three deadline columns. IDs stay stable as the minimum advances.
struct ClassDeadlineWheel {
  let maximumDate: Date
  private let initialMinimum: Date
  private static let calendar = AppDateFormat.calendar
  private static let epoch = calendar.startOfDay(for: Date(timeIntervalSince1970: 0))

  init(
    selection: Date,
    minimumDate: Date
  ) {
    initialMinimum = min(selection, minimumDate)
    let horizon = Self.calendar.date(byAdding: .year, value: 10, to: minimumDate) ?? minimumDate
    let selectedHorizon = Self.calendar.date(byAdding: .year, value: 1, to: selection) ?? selection
    maximumDate = min(max(horizon, selectedHorizon), Date.distantFuture.addingTimeInterval(-60))
  }

  func days(including selection: Date) -> ClosedRange<Int> {
    Self.dayID(min(initialMinimum, selection)) ... Self.dayID(maximumDate)
  }

  static func dayID(_ date: Date) -> Int {
    calendar.dateComponents([.day], from: epoch, to: calendar.startOfDay(for: date)).day ?? 0
  }

  static func date(for day: Int) -> Date {
    calendar.date(byAdding: .day, value: day, to: epoch) ?? epoch
  }

  static func hour(_ date: Date) -> Int {
    calendar.component(.hour, from: date)
  }

  static func minute(_ date: Date) -> Int {
    calendar.component(.minute, from: date)
  }

  func selecting(
    day: Int? = nil,
    hour: Int? = nil,
    minute: Int? = nil,
    from selection: Date,
    minimumDate: Date
  ) -> Date {
    let unchanged = (day == nil || day == Self.dayID(selection))
      && (hour == nil || hour == Self.hour(selection))
      && (minute == nil || minute == Self.minute(selection))
    if unchanged, selection >= minimumDate, selection <= maximumDate {
      return selection
    }
    let date = day.map(Self.date(for:)) ?? selection
    var components = Self.calendar.dateComponents([.year, .month, .day], from: date)
    components.hour = hour ?? Self.hour(selection)
    components.minute = minute ?? Self.minute(selection)
    components.second = 0
    let proposed = Self.calendar.date(from: components) ?? selection
    return min(max(proposed, minimumDate), maximumDate)
  }
}
