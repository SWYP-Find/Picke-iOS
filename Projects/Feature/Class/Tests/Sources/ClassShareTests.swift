//
//  ClassShareTests.swift
//  ClassTests
//
//  Created by Picke on 10/11/26.
//

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
    #expect(ClassShareFeature.State(room: room).deadlineText?.hasPrefix("참여 마감 · ") == true)
  }

  @Test
  func 클래스로_이동하면_이동_델리게이트를_보낸다() async {
    let store = TestStore(initialState: ClassShareFeature.State(room: room)) {
      ClassShareFeature()
    }

    await store.send(.view(.enterClassTapped))
    await store.receive(\.delegate.enterClass)
  }

  @Test
  func 목_클래스에서는_이름_입력_모달을_먼저_띄운다() async {
    let repository = MockClassRepository(rooms: [room])
    let store = TestStore(initialState: ClassShareFeature.State(room: room)) {
      ClassShareFeature()
    } withDependencies: {
      $0.classMockRepository = repository
    }

    await store.send(.view(.enterClassTapped)) {
      $0.join = .init(mode: .ownerName, preview: room)
    }
    await store.send(.join(.presented(.view(.backTapped))))
    await store.receive(\.join.presented.delegate.dismiss) {
      $0.join = nil
    }
  }

  @Test
  func 운영자_이름_저장_후_상세_화면_이동을_위임한다() async {
    let repository = MockClassRepository(rooms: [room])
    let store = TestStore(initialState: ClassShareFeature.State(room: room)) {
      ClassShareFeature()
    } withDependencies: {
      $0.classMockRepository = repository
    }

    await store.send(.view(.enterClassTapped)) {
      $0.join = .init(mode: .ownerName, preview: room)
    }
    await store.send(.join(.presented(.binding(.set(\.nickname, " 선생님 "))))) {
      $0.join?.nickname = " 선생님 "
    }
    await store.send(.join(.presented(.view(.joinTapped))))
    await store.receive(\.join.presented.async, .nameOwner(roomID: room.id, nickname: "선생님")) {
      $0.join?.isLoading = true
    }
    await store.receive(\.join.presented.inner, .ownerNamed(.success(room))) {
      $0.join?.isLoading = false
      $0.join?.preview = nil
    }
    await store.receive(\.join.presented.delegate.ownerNamed) {
      $0.join = nil
    }
    await store.receive(\.delegate.enterClass, room)
    let memberID = try? await repository.currentMemberID(roomID: room.id)
    let members = try? await repository.fetchMembers(roomID: room.id)
    #expect(members?.first(where: { $0.id == memberID })?.name == "선생님")
  }
}
