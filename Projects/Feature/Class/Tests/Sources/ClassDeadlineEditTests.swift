//
//  ClassDeadlineEditTests.swift
//  ClassTests
//
//  Created by Picke on 10/12/26.
//

@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct ClassDeadlineEditTests {
  private let referenceNow = Date(timeIntervalSince1970: 1_900_000_000)

  @Test
  func 운영자만_변경된_미래_마감일을_저장할_수_있다() {
    let original = makeRoom(deadline: referenceNow.addingTimeInterval(86400))
    let student = makeRoom(deadline: original.deadline, role: .member)
    var ownerState = ClassDeadlineEditFeature.State(
      room: original,
      instanceID: UUID(),
      referenceNow: referenceNow
    )
    var studentState = ClassDeadlineEditFeature.State(
      room: student,
      instanceID: UUID(),
      referenceNow: referenceNow
    )
    #expect(!ownerState.canSave)
    #expect(!studentState.canSave)
    let changedDeadline = referenceNow.addingTimeInterval(172_800)
    ownerState.draftDeadline = changedDeadline
    studentState.draftDeadline = changedDeadline
    #expect(ownerState.canSave)
    #expect(!studentState.canSave)
    #expect(ownerState.minimumSelectableDate == referenceNow)
  }

  @Test
  func 저장하지_않고_닫으면_취소를_전달한다() async {
    let store = TestStore(initialState: ClassDeadlineEditFeature.State(
      room: makeRoom(deadline: referenceNow.addingTimeInterval(86400)),
      instanceID: UUID(),
      referenceNow: referenceNow
    )) { ClassDeadlineEditFeature() }

    await store.send(.view(.backTapped))
    await store.receive(\.delegate, .dismiss)
  }

  @Test
  func 마감일을_끄고_다시_켜면_7일_후_선택일을_사용한다() async {
    let room = makeRoom(deadline: .distantFuture)
    let instanceID = UUID()
    let store = TestStore(initialState: ClassDeadlineEditFeature.State(
      room: room,
      instanceID: instanceID,
      referenceNow: referenceNow
    )) { ClassDeadlineEditFeature() } withDependencies: {
      $0.date.now = referenceNow.addingTimeInterval(3600)
    }

    #expect(!store.state.isDeadlineEnabled)
    #expect(!store.state.canSave)
    #expect(store.state.selectedDeadlineText == "마감일 없음")
    await store.send(.view(.deadlineEnabledChanged(true))) {
      $0.isDeadlineEnabled = true
      $0.draftDeadline = referenceNow.addingTimeInterval(604_800)
    }
    #expect(store.state.canSave)
    await store.send(.view(.deadlineEnabledChanged(false))) {
      $0.isDeadlineEnabled = false
    }
    #expect(!store.state.canSave)
  }

  @Test
  func 과거_마감일은_보여주되_그대로_저장할_수_없다() {
    let past = referenceNow.addingTimeInterval(-86400)
    let state = ClassDeadlineEditFeature.State(
      room: makeRoom(deadline: past),
      instanceID: UUID(),
      referenceNow: referenceNow
    )
    #expect(state.draftDeadline == past)
    #expect(state.minimumSelectableDate == past)
    #expect(state.validationMessage == "현재 이후 시간을 선택해 주세요.")
    #expect(!state.canSave)
  }

  @Test
  func 기존_마감일을_끄면_distantFuture를_저장한다() async {
    let room = makeRoom(deadline: referenceNow.addingTimeInterval(86400))
    let instanceID = UUID()
    let requestID = UUID()
    let repository = MockClassRepository(rooms: [room])
    let store = TestStore(initialState: ClassDeadlineEditFeature.State(
      room: room,
      instanceID: instanceID,
      referenceNow: referenceNow
    )) { ClassDeadlineEditFeature() } withDependencies: {
      $0.classUseCase = repository
      $0.date.now = referenceNow
      $0.uuid = .constant(requestID)
    }

    await store.send(.view(.deadlineEnabledChanged(false))) {
      $0.isDeadlineEnabled = false
    }
    #expect(store.state.canSave)
    await store.send(.view(.saveTapped)) {
      $0.activeRequestID = requestID
      $0.isSaving = true
    }
    await store.receive(\.async, .save(
      roomID: room.id,
      deadline: .distantFuture,
      instanceID: instanceID,
      requestID: requestID
    ))
    let updated = makeRoom(deadline: .distantFuture)
    await store.receive(\.inner, .saveResponse(
      .success(updated),
      roomID: room.id,
      instanceID: instanceID,
      requestID: requestID
    ))
    await store.receive(\.delegate, .saved(updated, instanceID: instanceID, requestID: requestID))
  }

  @Test
  func 저장_직전_현재_시간을_다시_검사한다() async {
    let original = makeRoom(deadline: referenceNow.addingTimeInterval(86400))
    let draft = referenceNow.addingTimeInterval(300)
    var state = ClassDeadlineEditFeature.State(
      room: original,
      instanceID: UUID(),
      referenceNow: referenceNow
    )
    state.draftDeadline = draft
    let store = TestStore(initialState: state) { ClassDeadlineEditFeature() } withDependencies: {
      $0.date.now = draft.addingTimeInterval(300)
    }
    #expect(store.state.canSave)

    await store.send(.view(.saveTapped)) {
      $0.errorMessage = "현재 이후 시간을 선택해 주세요."
    }
    #expect(!store.state.isSaving)
    #expect(store.state.activeRequestID == nil)
  }

  @Test
  func 저장_성공은_요청_식별자를_보존한_채_상위에_변경_결과를_전달한다() async {
    let room = makeRoom(deadline: referenceNow.addingTimeInterval(86400))
    let deadline = referenceNow.addingTimeInterval(172_800)
    let instanceID = UUID()
    let requestID = UUID()
    var state = ClassDeadlineEditFeature.State(
      room: room,
      instanceID: instanceID,
      referenceNow: referenceNow
    )
    state.draftDeadline = deadline
    let repository = MockClassRepository(rooms: [room])
    let store = TestStore(initialState: state) { ClassDeadlineEditFeature() } withDependencies: {
      $0.classUseCase = repository
      $0.date.now = referenceNow
      $0.uuid = .constant(requestID)
    }

    await store.send(.view(.saveTapped)) {
      $0.activeRequestID = requestID
      $0.isSaving = true
    }
    await store.receive(\.async, .save(
      roomID: room.id,
      deadline: deadline,
      instanceID: instanceID,
      requestID: requestID
    ))
    let updated = makeRoom(deadline: deadline)
    await store.receive(\.inner, .saveResponse(
      .success(updated),
      roomID: room.id,
      instanceID: instanceID,
      requestID: requestID
    ))
    await store.receive(\.delegate, .saved(updated, instanceID: instanceID, requestID: requestID))
    #expect(store.state.isSaving)
    #expect(store.state.activeRequestID == requestID)
  }

  @Test
  func 저장_실패는_폼을_남겨_수동_재시도할_수_있다() async {
    let room = makeRoom(deadline: referenceNow.addingTimeInterval(86400))
    let deadline = referenceNow.addingTimeInterval(172_800)
    let instanceID = UUID()
    let requestID = UUID()
    var state = ClassDeadlineEditFeature.State(
      room: room,
      instanceID: instanceID,
      referenceNow: referenceNow
    )
    state.draftDeadline = deadline
    let store = TestStore(initialState: state) { ClassDeadlineEditFeature() } withDependencies: {
      $0.classUseCase = MockClassRepository(rooms: [])
      $0.date.now = referenceNow
      $0.uuid = .constant(requestID)
    }

    await store.send(.view(.saveTapped)) {
      $0.activeRequestID = requestID
      $0.isSaving = true
    }
    await store.receive(\.async, .save(
      roomID: room.id,
      deadline: deadline,
      instanceID: instanceID,
      requestID: requestID
    ))
    await store.receive(\.inner, .saveResponse(
      .failure(.invalidCode),
      roomID: room.id,
      instanceID: instanceID,
      requestID: requestID
    )) {
      $0.isSaving = false
      $0.activeRequestID = nil
      $0.errorMessage = ClassError.invalidCode.message
    }
    #expect(store.state.draftDeadline == deadline)
    #expect(store.state.canSave)
  }

  @Test
  func 저장_중에는_중복_저장과_닫기를_막고_이전_응답을_무시한다() async {
    let room = makeRoom(deadline: referenceNow.addingTimeInterval(86400))
    let instanceID = UUID()
    let requestID = UUID()
    var state = ClassDeadlineEditFeature.State(
      room: room,
      instanceID: instanceID,
      referenceNow: referenceNow
    )
    state.draftDeadline = referenceNow.addingTimeInterval(172_800)
    state.isSaving = true
    state.activeRequestID = requestID
    let store = TestStore(initialState: state) { ClassDeadlineEditFeature() }

    await store.send(.view(.saveTapped))
    await store.send(.view(.backTapped))
    await store.send(.inner(.saveResponse(
      .success(makeRoom(deadline: state.draftDeadline)),
      roomID: room.id,
      instanceID: UUID(),
      requestID: requestID
    )))
    await store.send(.inner(.saveResponse(
      .failure(.invalidCode),
      roomID: room.id,
      instanceID: instanceID,
      requestID: UUID()
    )))
    await store.send(.inner(.saveResponse(
      .failure(.invalidCode),
      roomID: room.id + 1,
      instanceID: instanceID,
      requestID: requestID
    )))
    #expect(store.state.isSaving)
    #expect(store.state.activeRequestID == requestID)
    #expect(store.state.errorMessage == nil)
  }

  private func makeRoom(
    deadline: Date,
    role: ClassRole = .owner
  ) -> ClassRoom {
    let source = ClassRoom.mocks[0]
    return ClassRoom(
      id: source.id,
      name: source.name,
      joinCode: source.joinCode,
      battle: source.battle,
      deadline: deadline,
      memberCount: source.memberCount,
      role: role,
      status: source.status,
      allowsAnonymousOpinion: source.allowsAnonymousOpinion,
      requiresComment: source.requiresComment,
      ownerParticipates: source.ownerParticipates
    )
  }
}
