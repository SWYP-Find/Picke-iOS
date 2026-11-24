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
    let useCase = RetryProfileUseCase()
    let store = TestStore(initialState: ProfileFeature.State()) {
      ProfileFeature()
    } withDependencies: {
      $0.profileUseCase = useCase
    }

    await store.send(.async(.fetchProfile))
    await store.receive(\.inner, .myPageResponse(.failure(.networkError("offline")))) {
      $0.viewState = .error
    }

    await store.send(.view(.retryTapped))
    await store.receive(\.async, .fetchProfile) {
      $0.viewState = .loading
    }
    await store.receive(\.inner, .myPageResponse(.success(.sample))) {
      $0.viewState = .loaded
      $0.nickname = "테스터"
      $0.userCode = "picke42"
      $0.point = 120
      $0.philosopherType = "PLATO"
      $0.philosopherLabel = "플라톤"
      $0.philosopherImageURL = "https://example.com/philosopher.png"
      $0.profileImageURL = "https://example.com/avatar.png"
    }

    #expect(await useCase.fetchCount == 2)
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

private actor RetryProfileUseCase: ProfileInterface {
  private let fallback = MockProfileRepository()
  private(set) var fetchCount = 0

  func fetchMyPage() async throws -> MyPage {
    fetchCount += 1
    if fetchCount == 1 { throw ProfileError.networkError("offline") }
    return .sample
  }

  func fetchRecap() async throws -> PhilosopherRecap {
    try await fallback.fetchRecap()
  }

  func fetchCreditHistory(
    offset: Int?,
    size: Int
  ) async throws -> CreditHistoryPage {
    try await fallback.fetchCreditHistory(offset: offset, size: size)
  }

  func fetchBattleRecords(
    offset: Int,
    size: Int,
    voteSide: BattleVoteSide?
  ) async throws -> BattleRecordPage {
    try await fallback.fetchBattleRecords(offset: offset, size: size, voteSide: voteSide)
  }

  func fetchContentActivities(
    offset: Int,
    size: Int,
    activityType: ContentActivityType?
  ) async throws -> ContentActivityPage {
    try await fallback.fetchContentActivities(offset: offset, size: size, activityType: activityType)
  }

  func fetchNotificationSettings() async throws -> NotificationSettings {
    try await fallback.fetchNotificationSettings()
  }

  func updateNotificationSettings(_ settings: NotificationSettings) async throws -> NotificationSettings {
    try await fallback.updateNotificationSettings(settings)
  }

  func updateProfile(
    nickname: String,
    characterType: String
  ) async throws -> UpdatedProfile {
    try await fallback.updateProfile(nickname: nickname, characterType: characterType)
  }
}

private extension MyPage {
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
