//
//  ClassTests.swift
//  ClassTests
//
//  Created by Picke on 10/11/26.
//

@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Testing

@MainActor
struct ClassTests {
  @Test
  func 참여하기_탭하면_참가_경로_델리게이트를_보낸다() async {
    let store = TestStore(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature()
    }

    await store.send(.view(.joinTapped))
    await store.receive(\.delegate.join)
  }

  @Test
  func 뒤로가면_홈_이동_델리게이트를_보낸다() async {
    let store = TestStore(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature()
    }

    await store.send(.view(.backTapped))
    await store.receive(\.delegate.backToHome)
  }

  @Test
  func 내_클래스_탭하면_내_클래스_델리게이트를_보낸다() async {
    let store = TestStore(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature()
    }

    await store.send(.view(.myClassesTapped))
    await store.receive(\.delegate.myClasses)
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
  func Mock_이용권을_활성화하면_등록_화면으로_이동한다() async {
    let store = TestStore(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature()
    } withDependencies: {
      $0.classTicketMockEnabled = true
    }

    await store.send(.view(.ticketTapped))
    await store.receive(\.delegate.ticket)
  }

  @Test
  func Mock_이용권이_꺼져_있으면_기존_안내를_보여준다() async {
    let store = TestStore(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature()
    } withDependencies: {
      $0.classTicketMockEnabled = false
    }

    await store.send(.view(.ticketTapped)) {
      $0.customAlert = .alert(
        title: "이용권 등록 준비 중",
        message: "이용권 등록 기능은 아직 사용할 수 없습니다.",
        cancelTitle: ""
      )
    }
    await store.send(.customAlert(.presented(.confirmTapped))) {
      $0.customAlert = nil
    }
  }

  @Test
  func 같은_카테고리를_다시_누르면_선택이_해제된다() async {
    let store = TestStore(initialState: ClassTopicFeature.State()) {
      ClassTopicFeature()
    }

    await store.send(.view(.categoryTapped(.philosophy))) {
      $0.categories = [.philosophy]
    }
    await store.send(.view(.categoryTapped(.philosophy))) {
      $0.categories = []
    }
  }

  @Test
  func 카테고리는_최대_세_개까지_선택하고_해제하면_다시_추가할_수_있다() async {
    let store = TestStore(initialState: ClassTopicFeature.State()) {
      ClassTopicFeature()
    }

    await store.send(.view(.categoryTapped(.philosophy))) {
      $0.categories = [.philosophy]
    }
    await store.send(.view(.categoryTapped(.society))) {
      $0.categories = [.philosophy, .society]
    }
    await store.send(.view(.categoryTapped(.literature))) {
      $0.categories = [.philosophy, .society, .literature]
    }
    await store.send(.view(.categoryTapped(.science)))
    await store.send(.view(.categoryTapped(.society))) {
      $0.categories = [.philosophy, .literature]
    }
    await store.send(.view(.categoryTapped(.science))) {
      $0.categories = [.philosophy, .literature, .science]
    }
  }

  @Test
  func 콘텐츠_보기_탭하면_선택한_조건으로_검색_델리게이트를_보낸다() async {
    var state = ClassTopicFeature.State()
    state.keyword = "  촉법소년 "
    state.level = .high
    state.categories = [.society, .philosophy]
    let store = TestStore(initialState: state) {
      ClassTopicFeature()
    }

    await store.send(.view(.searchTapped))
    await store.receive(\.delegate.search, ClassTopicFilter(
      keyword: "촉법소년",
      level: .high,
      categories: [.society, .philosophy]
    ))
  }
}
