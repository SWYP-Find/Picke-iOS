//
//  ProfileTests.swift
//  ProfileTests
//
//  Created by Picke on 2026-06-08.
//

import ComposableArchitecture
import ProfileDomainInterface

@testable import Profile
import Testing

struct ProfileTests {
  @Test
  @MainActor
  func failedMyPageShowsErrorAndRetryLoadsProfile() async {
    let store = TestStore(initialState: ProfileFeature.State()) {
      ProfileFeature()
    }

    await store.send(.inner(.myPageResponse(.failure(.networkError("offline"))))) {
      $0.viewState = .error
    }

    await store.send(.view(.retryTapped))
    await store.receive(\.async, .fetchProfile) {
      $0.viewState = .loading
    }
    await store.receive(\.inner, .myPageResponse(.success(.empty))) {
      $0.viewState = .loaded
    }
  }

  @Test
  @MainActor
  func successfulMyPageDisplaysServerValues() async {
    let store = TestStore(initialState: ProfileFeature.State()) {
      ProfileFeature()
    }

    await store.send(.inner(.myPageResponse(.success(.sample)))) {
      $0.viewState = .loaded
      $0.nickname = "테스터"
      $0.userCode = "picke42"
      $0.point = 120
      $0.philosopherType = "PLATO"
      $0.philosopherLabel = "플라톤"
      $0.philosopherImageURL = "https://example.com/philosopher.png"
      $0.profileImageURL = "https://example.com/avatar.png"
    }
  }
}

private extension MyPage {
  static let empty = MyPage(
    profile: .empty,
    philosopher: .empty,
    tier: .empty
  )

  static let sample = MyPage(
    profile: MyProfile(
      userTag: "picke42",
      nickname: "테스터",
      characterType: "OWL",
      characterLabel: "부엉이",
      characterImageURL: "https://example.com/avatar.png",
      mannerTemperature: 36.5
    ),
    philosopher: MyPhilosopher(
      philosopherType: "PLATO",
      philosopherLabel: "플라톤",
      typeName: "PLATO",
      description: "",
      imageURL: "https://example.com/philosopher.png"
    ),
    tier: MyTier(
      tierCode: "WANDERER",
      tierLabel: "",
      currentPoint: 120
    )
  )
}
