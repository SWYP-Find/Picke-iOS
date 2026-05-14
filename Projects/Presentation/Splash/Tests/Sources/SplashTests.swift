//
//  SplashTests.swift
//  Presentation.SplashTests
//
//  Created by Roy on 2026-05-02.
//

import Testing
import ComposableArchitecture
import UseCase

@testable import Splash

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
      $0.keychainManager = keychainManager
    }

    await store.send(.view(.onAppear))
    await clock.advance(by: .seconds(0.5))
    await store.receive(.delegate(.presentMainTab))
  }

  @Test
  func onAppearRoutesToAuthWhenTokensDoNotExist() async {
    let clock = TestClock()

    let store = TestStore(initialState: SplashFeature.State()) {
      SplashFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0.keychainManager = InMemoryKeychainManager()
    }

    await store.send(.view(.onAppear))
    await clock.advance(by: .seconds(0.5))
    await store.receive(.delegate(.presentAuth))
  }
}
