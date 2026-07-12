//
//  SplashTests.swift
//  Presentation.SplashTests
//
//  Created by Roy on 2026-05-02.
//

import ComposableArchitecture
import Testing

import DomainInterface
import Entity
import UseCase

@testable import Splash

/// 앱 업데이트 없음(nil)을 반환하는 테스트 스텁.
private struct StubAppUpdateUseCase: AppUpdateUseCaseInterface {
  var info: AppUpdateInfo?
  func checkForUpdate() async throws -> AppUpdateInfo? { info }
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
    let keychainManager = InMemoryKeychainManager()
    keychainManager.save(accessToken: "access-token", refreshToken: "refresh-token")
    let clock = TestClock()

    let store = TestStore(initialState: SplashFeature.State()) {
      SplashFeature()
    } withDependencies: {
      $0.continuousClock = clock
      // keychainManager 접근자가 DomainInterface/UseCase 양쪽에 중복 정의되어 모호하므로,
      // SplashFeature 가 실제로 읽는 UseCase 의 키를 모듈 한정 subscript 로 오버라이드한다.
      $0.keychainManager = keychainManager
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
      $0.keychainManager = InMemoryKeychainManager()
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
