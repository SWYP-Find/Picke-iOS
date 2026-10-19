//
//  ClassTicketTests.swift
//  ClassTests
//

@testable import Class
import ComposableArchitecture
import Foundation
import PickeCoreUtility
import Testing

@MainActor
struct ClassTicketTests {
  @Test
  func 유효한_Mock_코드는_확인_뒤_등록되고_서울_날짜를_표시한다() async throws {
    let clock = TestClock()
    let registeredAt = try #require("2026.10.09".date(as: .yearMonthDayDotted))
    var state = ClassTicketFeature.State()
    state.code = "PICKE30"
    let store = TestStore(initialState: state) { ClassTicketFeature() } withDependencies: {
      $0.continuousClock = clock
      $0.date = .constant(registeredAt)
    }

    await store.send(.view(.checkTapped)) {
      $0.isChecking = true
    }
    await clock.advance(by: .milliseconds(350))
    await store.receive(\.checkResponse) {
      $0.isChecking = false
      $0.phase = .registered
      $0.registrationStartDate = registeredAt
      $0.expirationDate = "2027.04.08".date(as: .yearMonthDayDotted)
    }
    #expect(store.state.periodText == "2026.10.09 – 2027.04.08")
  }

  @Test
  func 유효하지_않은_코드는_입력_상태를_유지한다() async {
    let clock = TestClock()
    var state = ClassTicketFeature.State()
    state.code = "WRONG"
    let store = TestStore(initialState: state) { ClassTicketFeature() } withDependencies: {
      $0.continuousClock = clock
      $0.date = .constant(Date(timeIntervalSince1970: 0))
    }

    await store.send(.view(.checkTapped)) {
      $0.isChecking = true
    }
    await clock.advance(by: .milliseconds(350))
    await store.receive(\.checkResponse) {
      $0.isChecking = false
      $0.errorMessage = "유효하지 않은 이용권 코드예요. 다시 확인해 주세요."
    }
    #expect(store.state.phase == .entry)
  }

  @Test
  func 확인_중_코드를_바꾸면_이전_응답을_취소한다() async {
    let clock = TestClock()
    var state = ClassTicketFeature.State()
    state.code = "PICKE30"
    let store = TestStore(initialState: state) { ClassTicketFeature() } withDependencies: {
      $0.continuousClock = clock
      $0.date = .constant(Date(timeIntervalSince1970: 0))
    }

    await store.send(.view(.checkTapped)) {
      $0.isChecking = true
    }
    await store.send(.binding(.set(\.code, "PICKE3"))) {
      $0.code = "PICKE3"
      $0.isChecking = false
    }
    await clock.advance(by: .milliseconds(350))
    await store.finish(timeout: .seconds(1))
    #expect(store.state.phase == .entry)
  }

  @Test
  func 월말_등록은_서울_달력의_월_보정_정책을_따른다() async throws {
    for (start, end) in [
      ("2026.08.31", "2027.02.27"),
      ("2027.08.31", "2028.02.28"),
    ] {
      let clock = TestClock()
      let registeredAt = try #require(start.date(as: .yearMonthDayDotted))
      var state = ClassTicketFeature.State()
      state.code = "PICKE30"
      let store = TestStore(initialState: state) { ClassTicketFeature() } withDependencies: {
        $0.continuousClock = clock
        $0.date = .constant(registeredAt)
      }

      await store.send(.view(.checkTapped)) {
        $0.isChecking = true
      }
      await clock.advance(by: .milliseconds(350))
      await store.receive(\.checkResponse) {
        $0.isChecking = false
        $0.phase = .registered
        $0.registrationStartDate = registeredAt
        $0.expirationDate = end.date(as: .yearMonthDayDotted)
      }
      #expect(store.state.periodText == "\(start) – \(end)")
    }
  }

  @Test
  func 밤_열한시_오십구분에_등록해도_서울_기준_당일부터_계산한다() async throws {
    let clock = TestClock()
    let registeredAt = try #require(AppDateFormat.calendar.date(from: DateComponents(
      year: 2026,
      month: 10,
      day: 18,
      hour: 23,
      minute: 59
    )))
    var state = ClassTicketFeature.State()
    state.code = "PICKE30"
    let store = TestStore(initialState: state) { ClassTicketFeature() } withDependencies: {
      $0.continuousClock = clock
      $0.date = .constant(registeredAt)
    }

    await store.send(.view(.checkTapped)) {
      $0.isChecking = true
    }
    await clock.advance(by: .milliseconds(350))
    await store.receive(\.checkResponse) {
      $0.isChecking = false
      $0.phase = .registered
      $0.registrationStartDate = "2026.10.18".date(as: .yearMonthDayDotted)
      $0.expirationDate = "2027.04.17".date(as: .yearMonthDayDotted)
    }
    #expect(store.state.periodText == "2026.10.18 – 2027.04.17")
  }
}
