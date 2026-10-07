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
  func 참여하기_탭하면_코드_입력_모달을_띄운다() async {
    let store = TestStore(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature()
    }

    await store.send(.view(.joinTapped)) {
      $0.join = ClassJoinFeature.State()
    }
  }

  @Test
  func 코드_확인에_성공하면_코드_모달을_닫고_이름_입력_모달을_띄운다() async {
    let clock = TestClock()
    let room = ClassRoom.mockJoinable
    var state = ClassIntroFeature.State()
    state.join = ClassJoinFeature.State()
    let store = TestStore(initialState: state) {
      ClassIntroFeature()
    } withDependencies: {
      $0.continuousClock = clock
    }

    await store.send(.join(.presented(.delegate(.found(room))))) {
      $0.join = nil
    }
    await clock.advance(by: .seconds(0.3))
    await store.receive(\.inner.nicknameModalPresented, room) {
      $0.join = ClassJoinFeature.State(mode: .nickname, preview: room)
    }
  }

  @Test
  func 이름으로_참여하면_입력한_이름을_상위_델리게이트에_전달한다() async {
    let room = ClassRoom.mockJoinable
    var state = ClassIntroFeature.State()
    state.join = ClassJoinFeature.State(mode: .nickname, preview: room)
    let store = TestStore(initialState: state) {
      ClassIntroFeature()
    }

    await store.send(.join(.presented(.delegate(.joined(room, nickname: "민지"))))) {
      $0.join = nil
    }
    await store.receive(\.delegate, .joined(room, nickname: "민지"))
  }

  @Test
  func 이름_입력_모달_대기_중_뒤로가면_예약된_모달을_취소한다() async {
    let clock = TestClock()
    let room = ClassRoom.mockJoinable
    var state = ClassIntroFeature.State()
    state.join = ClassJoinFeature.State()
    let store = TestStore(initialState: state) {
      ClassIntroFeature()
    } withDependencies: {
      $0.continuousClock = clock
    }

    await store.send(.join(.presented(.delegate(.found(room))))) {
      $0.join = nil
    }
    await store.send(.view(.backTapped))
    await store.receive(\.delegate.backToHome)
    await clock.advance(by: .seconds(0.3))
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
  func 이용권_등록_기능이_없으면_안내를_표시한다() async {
    let store = TestStore(initialState: ClassIntroFeature.State()) {
      ClassIntroFeature()
    }

    await store.send(.view(.ticketTapped)) {
      $0.showTicketNotice = true
    }
    await store.send(.view(.ticketNoticeDismissed)) {
      $0.showTicketNotice = false
    }
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
