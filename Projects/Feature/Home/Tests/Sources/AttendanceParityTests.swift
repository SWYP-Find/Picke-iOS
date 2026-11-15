//
//  AttendanceParityTests.swift
//  HomeTests
//
//  Created by Picke on 11/11/26.
//

import AttendanceDomainInterface
import ComposableArchitecture
import Foundation
@testable import Home
import PickeCoreUtility
import Testing

/// Android `AppLifecycleObserver.checkAttendanceIfNeeded` · `HomeViewModel.checkInAndShowAttendanceSheetIfNeeded` 와 맞춘 출석.
@MainActor
@Suite(.serialized)
struct AttendanceParityTests {
  /// 2026-11-11 12:00 KST
  private static let now = Date(timeIntervalSince1970: 1_794_366_000)

  init() {
    UserDefaults.standard.removeObject(forKey: AttendanceDayRecord.checkedKey)
    UserDefaults.standard.removeObject(forKey: AttendanceDayRecord.sheetShownKey)
  }

  @Test
  func dayStringUsesKoreanTime() {
    // 2026-11-10 15:30 UTC = 2026-11-11 00:30 KST
    let date = Date(timeIntervalSince1970: 1_794_324_600)
    #expect(date.formatted(.yearMonthDay) == "2026-11-11")
  }

  @Test
  func returningToAppChecksAttendanceOncePerDay() async {
    let store = Self.store(FakeAttendance(checkSucceeds: true))
    let today = Self.now.formatted(.yearMonthDay)

    await store.send(.view(.appBecameActive))
    await store.receive(\.async, .checkAttendanceOnly(day: today))
    await store.receive(\.inner, .attendanceChecked(day: today))
    #expect(AttendanceDayRecord().isChecked(on: today))

    // 같은 날 다시 돌아오면 부르지 않는다.
    await store.send(.view(.appBecameActive))
  }

  @Test
  func failedCheckIsRetriedOnNextReturn() async {
    let store = Self.store(FakeAttendance(checkSucceeds: false))
    let today = Self.now.formatted(.yearMonthDay)

    await store.send(.view(.appBecameActive))
    await store.receive(\.async, .checkAttendanceOnly(day: today))
    await store.finish()
    #expect(!AttendanceDayRecord().isChecked(on: today))
  }

  @Test
  func sheetShowsEvenWhenAlreadyAttended() async {
    let store = Self.store(FakeAttendance(checkSucceeds: false))
    let today = Self.now.formatted(.yearMonthDay)

    await store.send(.async(.checkAttendance(day: today)))
    await store.receive(\.inner)
    #expect(store.state.attendanceModal != nil)
    #expect(AttendanceDayRecord().isSheetShown(on: today))
  }
}

extension AttendanceParityTests {
  private static func store(_ attendance: FakeAttendance) -> TestStoreOf<HomeFeature> {
    let store = TestStore(initialState: HomeFeature.State()) {
      HomeFeature()
    } withDependencies: {
      $0.attendanceUseCase = attendance
      $0.date = .constant(now)
    }
    store.exhaustivity = .off
    return store
  }
}

private struct FakeAttendance: AttendanceInterface {
  struct Failure: Error {}
  let checkSucceeds: Bool

  func checkAttendance() async throws -> AttendanceCheckResult {
    guard checkSucceeds else { throw Failure() }
    return .empty
  }

  func fetchWeeklyAttendance() async throws -> WeeklyAttendance {
    .empty
  }

  func fetchAttendanceSummary() async throws -> AttendanceSummary {
    .empty
  }
}
