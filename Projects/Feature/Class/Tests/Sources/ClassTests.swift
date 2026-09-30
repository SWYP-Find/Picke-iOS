//
//  ClassTests.swift
//  Feature.ClassTests
//

@testable import Class
import ComposableArchitecture
import Testing

@MainActor
struct ClassTests {
  @Test
  func 참여하기_탭하면_참여_델리게이트를_보낸다() async {
    let store = TestStore(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature()
    }

    await store.send(.view(.joinTapped))
    await store.receive(\.delegate.join)
  }

  @Test
  func 새_클래스_만들기_탭하면_생성_델리게이트를_보낸다() async {
    let store = TestStore(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature()
    }

    await store.send(.view(.createTapped))
    await store.receive(\.delegate.create)
  }
}
