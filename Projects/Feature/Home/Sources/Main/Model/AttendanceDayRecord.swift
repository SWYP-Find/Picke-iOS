//
//  AttendanceDayRecord.swift
//  Home
//
//  Created by Picke on 11/11/26.
//

import Foundation

/// Android `LocalPreferences` 의 마지막 출석 체크일·시트 노출일. 날짜는 `Date.formatted(.yearMonthDay)` (한국 시간 `yyyy-MM-dd`).
public struct AttendanceDayRecord {
  static let checkedKey = "picke.attendance.lastCheckedDate"
  static let sheetShownKey = "picke.attendance.lastSheetShownDate"

  private let defaults: UserDefaults

  public init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  public func isChecked(on day: String) -> Bool {
    defaults.string(forKey: Self.checkedKey) == day
  }

  public func markChecked(on day: String) {
    defaults.set(day, forKey: Self.checkedKey)
  }

  public func isSheetShown(on day: String) -> Bool {
    defaults.string(forKey: Self.sheetShownKey) == day
  }

  public func markSheetShown(on day: String) {
    defaults.set(day, forKey: Self.sheetShownKey)
  }
}
