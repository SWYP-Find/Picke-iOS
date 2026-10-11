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
    #expect(store.state.join == nil)
    await clock.advance(by: .seconds(0.1))
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
  func 이름_입력_모달의_바인딩은_자식_리듀서에_전달된다() async {
    let room = ClassRoom.mockJoinable
    var state = ClassIntroFeature.State()
    state.join = ClassJoinFeature.State(mode: .nickname, preview: room)
    let store = TestStore(initialState: state) {
      ClassIntroFeature()
    }

    await store.send(.join(.presented(.binding(.set(\.nickname, "로이"))))) {
      $0.join?.nickname = "로이"
    }
    #expect(store.state.join?.canJoin == true)
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
    await clock.advance(by: .seconds(0.4))
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
