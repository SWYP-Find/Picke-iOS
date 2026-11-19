//
//  ClassEditTests.swift
//  ClassTests
//
//  Created by Picke on 11/11/26.
//

@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct ClassEditTests {
  private let referenceNow = Date(timeIntervalSince1970: 1_900_000_000)

  @Test
  func 이름이나_마감일을_바꿔야_운영자가_저장할_수_있다() {
    var owner = ClassEditFeature.State(room: makeRoom())
    var member = ClassEditFeature.State(room: makeRoom(role: .member))
    #expect(!owner.canSave)

    owner.name = "  새 클래스 이름  "
    member.name = "새 클래스 이름"
    #expect(owner.trimmedName == "새 클래스 이름")
    #expect(owner.canSave)
    #expect(!member.canSave)
  }

  @Test
  func 이름만_바꾸면_마감일_없이_PATCH_한_번으로_저장하고_결과를_전달한다() async {
    let room = makeRoom()
    let renamed = makeRoom(name: "새 클래스 이름")
    let calls = LockIsolated<[String]>([])
    var state = ClassEditFeature.State(room: room)
    state.name = "새 클래스 이름"
    let store = TestStore(initialState: state) { ClassEditFeature() } withDependencies: {
      $0.classRoomUseCase = ClassEditRoomStub(
        onUpdateName: { _ in renamed },
        onUpdateDeadline: { _ in room },
        calls: calls
      )
    }

    await store.send(.view(.saveTapped)) {
      $0.isSaving = true
    }
    await store.receive(\.inner, .saveResponse(.success(renamed))) {
      $0.isSaving = false
      $0.room = renamed
    }
    await store.receive(\.delegate, .saved(renamed))
    // Android ClassEditViewModel.updateClass: 이름은 항상, 마감일은 바뀐 경우만 한 번에 보낸다.
    #expect(calls.value == ["class:새 클래스 이름|nil"])
  }

  @Test
  func 빈_이름은_저장하지_않고_오류를_보여준다() async {
    var state = ClassEditFeature.State(room: makeRoom())
    state.name = "   "
    let store = TestStore(initialState: state) { ClassEditFeature() }

    await store.send(.view(.saveTapped)) {
      $0.isNameInvalid = true
    }
  }

  @Test
  func 기존_마감일보다_앞당기면_저장하지_않는다() async {
    let room = makeRoom()
    var state = ClassEditFeature.State(room: room)
    state.deadline = room.deadline.addingTimeInterval(-3600)
    let store = TestStore(initialState: state) { ClassEditFeature() }

    await store.send(.view(.saveTapped)) {
      $0.deadlineValidationMessage = "기존 마감일 이후부터 이용권 종료일까지 선택할 수 있어요"
    }
  }

  @Test
  func 마감일_필드는_마감일이_있는_클래스만_선택을_요청한다() async {
    let withDeadline = ClassEditFeature.State(room: makeRoom())
    let store = TestStore(initialState: withDeadline) { ClassEditFeature() }
    await store.send(.view(.deadlineFieldTapped))
    await store.receive(\.delegate, .editDeadline(instanceID: withDeadline.instanceID))

    let noDeadline = TestStore(
      initialState: ClassEditFeature.State(room: makeRoom(deadline: .distantFuture))
    ) { ClassEditFeature() }
    await noDeadline.send(.view(.deadlineFieldTapped))
  }

  @Test
  func 서버_마감일_오류는_마감일_범위_안내로_보여준다() async {
    let room = makeRoom()
    var state = ClassEditFeature.State(room: room)
    state.deadline = room.deadline.addingTimeInterval(3600)
    let store = TestStore(initialState: state) { ClassEditFeature() } withDependencies: {
      $0.classRoomUseCase = ClassEditRoomStub(
        onUpdateName: { _ in room },
        onUpdateDeadline: { _ in throw ClassError.deadlineExtensionOnly }
      )
    }

    await store.send(.view(.saveTapped)) {
      $0.isSaving = true
    }
    await store.receive(\.inner, .saveResponse(.failure(.deadlineExtensionOnly))) {
      $0.isSaving = false
      $0.deadlineValidationMessage = "기존 마감일 이후부터 이용권 종료일까지 선택할 수 있어요"
    }
  }

  @Test
  func 이용권_종료일_당일은_시각과_상관없이_고를_수_있다() async {
    let ticketEnd = Calendar.current.startOfDay(for: referenceNow.addingTimeInterval(86400 * 3))
    let room = makeRoom(ticketExpiresAt: ticketEnd)
    var sameDay = ClassEditFeature.State(room: room)
    sameDay.deadline = ticketEnd.addingTimeInterval(3600 * 20)
    let store = TestStore(initialState: sameDay) { ClassEditFeature() } withDependencies: {
      $0.classRoomUseCase = ClassEditRoomStub(
        onUpdateName: { _ in room },
        onUpdateDeadline: { _ in room }
      )
    }
    await store.send(.view(.saveTapped)) {
      $0.isSaving = true
    }
    await store.receive(\.inner, .saveResponse(.success(room))) {
      $0.isSaving = false
    }
    await store.receive(\.delegate, .saved(room))

    var nextDay = ClassEditFeature.State(room: room)
    nextDay.deadline = ticketEnd.addingTimeInterval(86400 + 60)
    let rejected = TestStore(initialState: nextDay) { ClassEditFeature() }
    await rejected.send(.view(.saveTapped)) {
      $0.deadlineValidationMessage = "기존 마감일 이후부터 이용권 종료일까지 선택할 수 있어요"
    }
  }

  private func makeRoom(
    name: String? = nil,
    deadline: Date? = nil,
    role: ClassRole = .owner,
    ticketExpiresAt: Date? = nil
  ) -> ClassRoom {
    let source = ClassRoom.mocks[0]
    return ClassRoom(
      id: source.id,
      name: name ?? source.name,
      joinCode: source.joinCode,
      battle: source.battle,
      deadline: deadline ?? referenceNow.addingTimeInterval(86400),
      memberCount: source.memberCount,
      role: role,
      status: source.status,
      allowsAnonymousOpinion: source.allowsAnonymousOpinion,
      requiresComment: source.requiresComment,
      ownerParticipates: source.ownerParticipates,
      memberCapacity: source.memberCapacity,
      ticketExpiresAt: ticketExpiresAt
    )
  }
}

private struct ClassEditRoomStub: ClassRoomInterface {
  let onUpdateName: @Sendable (String) async throws -> ClassRoom
  let onUpdateDeadline: @Sendable (Date) async throws -> ClassRoom
  var calls: LockIsolated<[String]>?

  init(
    onUpdateName: @escaping @Sendable (String) async throws -> ClassRoom,
    onUpdateDeadline: @escaping @Sendable (Date) async throws -> ClassRoom,
    calls: LockIsolated<[String]>? = nil
  ) {
    self.onUpdateName = onUpdateName
    self.onUpdateDeadline = onUpdateDeadline
    self.calls = calls
  }

  func updateClass(id _: Int, name: String, deadline: Date?) async throws -> ClassRoom {
    calls?.withValue { $0.append("class:\(name)|\(deadline.map { _ in "deadline" } ?? "nil")") }
    var updated = try await onUpdateName(name)
    if let deadline {
      updated = try await onUpdateDeadline(deadline)
    }
    return updated
  }

  func updateName(id _: Int, name: String) async throws -> ClassRoom {
    try await onUpdateName(name)
  }

  func updateDeadline(id _: Int, deadline: Date) async throws -> ClassRoom {
    try await onUpdateDeadline(deadline)
  }

  func fetchMyClasses() async throws -> [ClassRoom] {
    []
  }

  func createClass(_: ClassCreation) async throws -> ClassRoom {
    throw ClassError.userMessage("unused")
  }

  func fetchClass(id _: Int) async throws -> ClassRoom {
    throw ClassError.userMessage("unused")
  }

  func fetchClass(joinCode _: String) async throws -> ClassRoom {
    throw ClassError.userMessage("unused")
  }

  func joinClass(joinCode _: String,
                 nickname _: String) async throws -> ClassRoom
  {
    throw ClassError.userMessage("unused")
  }

  func deleteClass(id _: Int) async throws {}
  func leaveClass(id _: Int) async throws {}
}
