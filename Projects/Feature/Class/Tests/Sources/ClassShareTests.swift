@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct ClassShareTests {
  private let room = ClassRoom.mocks[0]

  @Test
  func 공유_문구에_클래스명과_참여코드를_담는다() {
    let state = ClassShareFeature.State(room: room)
    #expect(state.shareMessage.contains(room.name))
    #expect(state.shareMessage.contains(room.joinCode))
  }

  @Test
  func 마감일이_없는_클래스는_마감_문구를_숨긴다() {
    let noDeadline = ClassRoom(
      id: room.id,
      name: room.name,
      joinCode: room.joinCode,
      battle: room.battle,
      deadline: .distantFuture,
      memberCount: room.memberCount,
      role: room.role,
      status: room.status,
      allowsAnonymousOpinion: room.allowsAnonymousOpinion,
      requiresComment: room.requiresComment
    )
    #expect(ClassShareFeature.State(room: noDeadline).deadlineText == nil)
    #expect(ClassShareFeature.State(room: room).deadlineText != nil)
  }

  @Test
  func 클래스로_이동하면_이동_델리게이트를_보낸다() async {
    let store = TestStore(initialState: ClassShareFeature.State(room: room)) {
      ClassShareFeature()
    }

    await store.send(.view(.enterClassTapped))
    await store.receive(\.delegate.enterClass)
  }
}
