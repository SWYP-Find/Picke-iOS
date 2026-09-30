//
//  ClassTests.swift
//  Feature.ClassTests
//

@testable import Class
import ClassDomainInterface
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

  @Test
  func 같은_카테고리를_다시_누르면_선택이_해제된다() async {
    let store = TestStore(initialState: ClassTopicFeature.State()) {
      ClassTopicFeature()
    }

    await store.send(.view(.categoryTapped(.philosophy))) {
      $0.category = .philosophy
    }
    await store.send(.view(.categoryTapped(.philosophy))) {
      $0.category = nil
    }
  }

  @Test
  func 콘텐츠_보기_탭하면_선택한_조건으로_검색_델리게이트를_보낸다() async {
    var state = ClassTopicFeature.State()
    state.keyword = "  촉법소년 "
    state.level = .high
    state.category = .society
    let store = TestStore(initialState: state) {
      ClassTopicFeature()
    }

    await store.send(.view(.searchTapped))
    await store.receive(\.delegate.search, ClassTopicFilter(
      keyword: "촉법소년",
      level: .high,
      category: .society
    ))
  }
}
