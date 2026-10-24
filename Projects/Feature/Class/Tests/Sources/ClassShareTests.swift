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
      requiresComment: room.requiresComment,
      memberCapacity: room.memberCapacity
    )
    #expect(ClassShareFeature.State(room: noDeadline).deadlineText == nil)
    #expect(ClassShareFeature.State(room: room).deadlineText?.hasPrefix("참여 마감 · ") == true)
  }

  @Test
  func 운영자가_참여하지_않는_클래스로_바로_이동한다() async {
    let nonParticipatingRoom = ClassRoom(
      id: room.id,
      name: room.name,
      joinCode: room.joinCode,
      battle: room.battle,
      deadline: room.deadline,
      memberCount: room.memberCount,
      role: room.role,
      status: room.status,
      allowsAnonymousOpinion: room.allowsAnonymousOpinion,
      requiresComment: room.requiresComment,
      ownerParticipates: false
    )
    let store = TestStore(initialState: ClassShareFeature.State(room: nonParticipatingRoom)) {
      ClassShareFeature()
    }

    await store.send(.view(.enterClassTapped))
    await store.receive(\.delegate, .enterClass(nonParticipatingRoom))
  }

  @Test
  func 운영자가_참여하는_클래스에서는_운영자_이름_경로를_요청한다() async {
    let store = TestStore(initialState: ClassShareFeature.State(room: room)) {
      ClassShareFeature()
    }

    await store.send(.view(.enterClassTapped))
    await store.receive(\.delegate, .nameOwner(room))
  }

  @Test
  func 이름_경로_요청은_공유_화면을_유지한다() async {
    let store = TestStore(initialState: ClassShareFeature.State(room: room)) {
      ClassShareFeature()
    }

    await store.send(.view(.enterClassTapped))
    await store.receive(\.delegate, .nameOwner(room))
    #expect(store.state.room == room)
  }
}
