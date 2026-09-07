//
//  SplashTests.swift
//  Feature.SplashTests
//
//  Created by Roy on 2026-05-02.
//

import ComposableArchitecture
import Testing

import PickeAnalyticsInterface
import AppUpdateDomainInterface
import PickeAuthInterface

@testable import Splash

/// 앱 업데이트 없음(nil)을 반환하는 테스트 스텁.
private struct StubAppUpdateUseCase: AppUpdateUseCaseInterface {
  var info: AppUpdateInfo?
  func checkForUpdate() async throws -> AppUpdateInfo? { info }
}

/// 저장된 토큰 유무만 흉내내는 인증 서비스 스텁.
private actor StubAuthService: AuthService {
  private var loggedIn: Bool

  init(loggedIn: Bool) {
    self.loggedIn = loggedIn
  }

  var isLoggedIn: Bool { loggedIn }
  var refreshToken: String? { loggedIn ? "refresh-token" : nil }

  func signIn(accessToken _: String, refreshToken _: String) { loggedIn = true }
  func signOut() { loggedIn = false }
}

/// Mixpanel 을 건드리지 않는 no-op 분석 UseCase.
private let noopAnalytics = AnalyticsUseCase(
  registerBaseProperties: {},
  identify: { _, _ in },
  track: { _ in },
  reset: {}
)

struct SplashTests {
  @Test
  func onAppearRoutesToMainTabWhenTokensExist() async {
    let clock = TestClock()

    let store = TestStore(initialState: SplashFeature.State()) {
      SplashFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0.authService = StubAuthService(loggedIn: true)
      $0.appUpdateUseCase = StubAppUpdateUseCase(info: nil)
      $0.analyticsUseCase = noopAnalytics
    }

    await store.send(.view(.onAppear))
    await clock.advance(by: .seconds(1.2))
    await store.receive(\.async.checkAppUpdate)
    await store.receive(\.inner.checkAppUpdateResponse)
    await store.receive(\.delegate.presentMainTab)
  }

  @Test
  func onAppearRoutesToAuthWhenTokensDoNotExist() async {
    let clock = TestClock()

    let store = TestStore(initialState: SplashFeature.State()) {
      SplashFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0.authService = StubAuthService(loggedIn: false)
      $0.appUpdateUseCase = StubAppUpdateUseCase(info: nil)
      $0.analyticsUseCase = noopAnalytics
    }

    await store.send(.view(.onAppear))
    await clock.advance(by: .seconds(1.2))
    await store.receive(\.async.checkAppUpdate)
    await store.receive(\.inner.checkAppUpdateResponse)
    await store.receive(\.delegate.presentAuth)
  }
}
