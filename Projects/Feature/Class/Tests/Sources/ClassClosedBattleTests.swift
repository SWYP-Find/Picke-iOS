@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Testing

@MainActor
struct ClassClosedBattleTests {
  @Test
  func 결과_버튼은_현재_클래스의_리포트를_요청한다() async {
    let room = ClassRoom.mockClosedSociety
    let store = TestStore(initialState: ClassClosedBattleFeature.State(room: room)) {
      ClassClosedBattleFeature()
    }

    await store.send(.view(.resultTapped))
    await store.receive(\.delegate, .openReport(room))
  }

  @Test
  func 뒤로가기는_종료_화면만_닫는다() async {
    let store = TestStore(initialState: ClassClosedBattleFeature.State(room: .mockClosedSociety)) {
      ClassClosedBattleFeature()
    }

    await store.send(.view(.backTapped))
    await store.receive(\.delegate, .dismiss)
  }
}
