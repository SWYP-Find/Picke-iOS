//
//  ClassJoinTests.swift
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
struct ClassJoinTests {
  @Test
  func 뒤로가기는_닫기_델리게이트를_보낸다() async {
    let store = TestStore(initialState: ClassJoinFeature.State()) {
      ClassJoinFeature()
    }

    await store.send(.view(.backTapped))
    await store.receive(\.delegate.dismiss)
  }

  @Test
  func 참여코드를_조회하면_코드_모달을_닫기_위해_클래스를_전달한다() async {
    let room = ClassRoom.mockJoinable
    let store = TestStore(initialState: ClassJoinFeature.State()) {
      ClassJoinFeature()
    } withDependencies: {
      $0.classUseCase = StubClassUseCase(fetchClass: { _ in room })
    }

    await store.send(.binding(.set(\.joinCode, " pk9t3s "))) {
      $0.joinCode = "PK9T3S"
    }
    await store.send(.view(.findTapped))
    await store.receive(\.async, .find("PK9T3S")) {
      $0.isLoading = true
    }
    await store.receive(\.inner, .found(.success(room))) {
      $0.isLoading = false
    }
    await store.receive(\.delegate.found, room)
  }

  @Test
  func 이름을_입력하고_참여하면_클래스_참여_델리게이트를_보낸다() async {
    let room = ClassRoom.mockJoinable
    var state = ClassJoinFeature.State(mode: .nickname, preview: room)
    state.nickname = " 민지 "
    let store = TestStore(initialState: state) {
      ClassJoinFeature()
    } withDependencies: {
      $0.classUseCase = StubClassUseCase(joinClass: { code, nickname in
        #expect(code == room.joinCode)
        #expect(nickname == "민지")
        return room
      })
    }

    await store.send(.view(.joinTapped))
    await store.receive(\.async, .join(joinCode: room.joinCode, nickname: "민지")) {
      $0.isLoading = true
    }
    await store.receive(\.inner, .joined(.success(room), nickname: "민지")) {
      $0.preview = nil
      $0.isLoading = false
    }
    await store.receive(\.delegate, .joined(room, nickname: "민지"))
  }

  @Test
  func 운영자_이름은_참여_API_호출_없이_목_저장소에_저장한다() async throws {
    let room = ClassRoom.mocks[0]
    let repository = MockClassRepository(rooms: [room])
    var state = ClassJoinFeature.State(mode: .ownerName, preview: room)
    state.nickname = " 새 운영자 "
    let store = TestStore(initialState: state) {
      ClassJoinFeature()
    } withDependencies: {
      $0.classMockRepository = repository
      $0.classUseCase = StubClassUseCase(joinClass: { _, _ in
        Issue.record("운영자 이름 저장에서 joinClass를 호출하면 안 됩니다.")
        throw ClassError.invalidCode
      })
    }

    await store.send(.view(.joinTapped))
    await store.receive(\.async.nameOwner) {
      $0.isLoading = true
    }
    await store.receive(\.inner.ownerNamed) {
      $0.isLoading = false
      $0.preview = nil
    }
    await store.receive(\.delegate.ownerNamed, room)

    let memberID = try await repository.currentMemberID(roomID: room.id)
    let members = try await repository.fetchMembers(roomID: room.id)
    #expect(members.first(where: { $0.id == memberID })?.name == "새 운영자")
  }

  @Test
  func 운영자_이름이_비어_있으면_저장하지_않는다() async {
    let room = ClassRoom.mocks[0]
    let store = TestStore(initialState: ClassJoinFeature.State(mode: .ownerName, preview: room)) {
      ClassJoinFeature()
    }

    #expect(!store.state.canJoin)
    await store.send(.view(.joinTapped))
  }

  @Test
  func 이름은_공백을_제외한_문자_기준_12자까지_참여할_수_있다() async {
    let room = ClassRoom.mockJoinable
    let store = TestStore(initialState: ClassJoinFeature.State(mode: .nickname, preview: room)) {
      ClassJoinFeature()
    }
    let twelveCharacters = String(repeating: "가", count: 11) + "👩🏽‍💻"

    await store.send(.binding(.set(\.nickname, "  \(twelveCharacters)  "))) {
      $0.nickname = "  \(twelveCharacters)  "
    }
    #expect(store.state.nicknameCharacterCount == 12)
    #expect(store.state.canJoin)
    #expect(store.state.nicknameValidationMessage == nil)

    await store.send(.binding(.set(\.nickname, twelveCharacters + "나"))) {
      $0.nickname = twelveCharacters + "나"
    }
    #expect(store.state.nicknameCharacterCount == 13)
    #expect(!store.state.canJoin)
    #expect(store.state.nicknameValidationMessage != nil)
    #expect(store.state.nickname == twelveCharacters + "나")

    await store.send(.binding(.set(\.nickname, " \n "))) {
      $0.nickname = " \n "
    }
    #expect(store.state.nicknameCharacterCount == 0)
    #expect(!store.state.canJoin)
    await store.send(.view(.joinTapped))
  }

  @Test
  func 이름을_편집하면_서버와_이름_오류를_지우고_긴_이름은_로컬_오류를_우선한다() async {
    let room = ClassRoom.mockJoinable
    var state = ClassJoinFeature.State(mode: .nickname, preview: room)
    state.nickname = String(repeating: "가", count: 13)
    state.errorMessage = "이전 서버 오류"
    state.nicknameErrorMessage = ClassError.duplicateName.message
    let store = TestStore(initialState: state) { ClassJoinFeature() }

    #expect(store.state.nicknameValidationMessage == "이름은 12자 이내로 입력해 주세요.")
    #expect(store.state.nicknameErrorMessage == ClassError.duplicateName.message)
    #expect(!store.state.canJoin)

    await store.send(.binding(.set(\.nickname, "민지"))) {
      $0.nickname = "민지"
      $0.errorMessage = nil
      $0.nicknameErrorMessage = nil
    }
    #expect(store.state.nicknameCharacterCount == 2)
    #expect(store.state.nicknameValidationMessage == nil)
    #expect(store.state.canJoin)
  }

  @Test
  func 중복된_이름만_이름_오류로_표시하고_일반_서버_오류는_별도로_표시한다() async {
    let room = ClassRoom.mockJoinable
    var state = ClassJoinFeature.State(mode: .nickname, preview: room)
    state.nickname = "민지"
    let duplicateStore = TestStore(initialState: state) { ClassJoinFeature() }

    await duplicateStore.send(.inner(.joined(.failure(.duplicateName), nickname: "민지"))) {
      $0.nicknameErrorMessage = ClassError.duplicateName.message
    }
    #expect(duplicateStore.state.nicknameValidationMessage == ClassError.duplicateName.message)
    #expect(duplicateStore.state.errorMessage == nil)

    let ownerStore = TestStore(initialState: ClassJoinFeature.State(mode: .ownerName, preview: room)) {
      ClassJoinFeature()
    }
    await ownerStore.send(.inner(.ownerNamed(.failure(.duplicateName)))) {
      $0.nicknameErrorMessage = ClassError.duplicateName.message
    }
    #expect(ownerStore.state.errorMessage == nil)

    let generalStore = TestStore(initialState: state) { ClassJoinFeature() }
    await generalStore.send(.inner(.joined(.failure(.closed), nickname: "민지"))) {
      $0.errorMessage = ClassError.closed.message
    }
    #expect(generalStore.state.nicknameErrorMessage == nil)
    #expect(generalStore.state.nicknameValidationMessage == nil)
  }

  @Test
  func 이름_요청을_시작할_때_두_오류를_초기화한다() async {
    let room = ClassRoom.mockJoinable
    var state = ClassJoinFeature.State(mode: .nickname, preview: room)
    state.nickname = "민지"
    state.errorMessage = "이전 서버 오류"
    state.nicknameErrorMessage = ClassError.duplicateName.message
    let store = TestStore(initialState: state) {
      ClassJoinFeature()
    } withDependencies: {
      $0.classUseCase = StubClassUseCase(joinClass: { _, _ in room })
    }

    await store.send(.view(.joinTapped))
    await store.receive(\.async, .join(joinCode: room.joinCode, nickname: "민지")) {
      $0.isLoading = true
      $0.errorMessage = nil
      $0.nicknameErrorMessage = nil
    }
    await store.receive(\.inner, .joined(.success(room), nickname: "민지")) {
      $0.isLoading = false
      $0.preview = nil
    }
    await store.receive(\.delegate, .joined(room, nickname: "민지"))
  }

  @Test
  func 잘못된_코드_조회는_오류를_상태에_저장한다() async {
    let store = TestStore(initialState: ClassJoinFeature.State()) {
      ClassJoinFeature()
    } withDependencies: {
      $0.classUseCase = StubClassUseCase(fetchClass: { _ in
        throw ClassError.invalidCode
      })
    }

    await store.send(.binding(.set(\.joinCode, "BAD123"))) {
      $0.joinCode = "BAD123"
    }
    await store.send(.view(.findTapped))
    await store.receive(\.async, .find("BAD123")) {
      $0.isLoading = true
    }
    await store.receive(\.inner, .found(.failure(.invalidCode))) {
      $0.isLoading = false
      $0.errorMessage = "참여 코드를 다시 확인해 주세요."
    }
  }

  @Test
  func 붙여넣은_코드는_영문숫자만_대문자로_6자리까지_저장한다() async {
    let store = TestStore(initialState: ClassJoinFeature.State()) {
      ClassJoinFeature()
    }

    await store.send(.binding(.set(\.joinCode, " ab-12한글cd9 "))) {
      $0.joinCode = "AB12CD"
    }
    #expect(store.state.canFindClass)
  }

  @Test
  func 여섯자리_미만_또는_한글_조합_중에는_코드를_조회하지_않는다() async {
    let store = TestStore(initialState: ClassJoinFeature.State()) {
      ClassJoinFeature()
    }

    await store.send(.binding(.set(\.joinCode, "a1가나"))) {
      $0.joinCode = "A1"
    }
    #expect(!store.state.canFindClass)
    await store.send(.view(.findTapped))
  }
}

private struct StubClassUseCase: ClassInterface {
  var fetchClass: @Sendable (String) async throws -> ClassRoom = { _ in .mockJoinable }
  var joinClass: @Sendable (String, String) async throws -> ClassRoom = { _, _ in .mockJoinable }

  func fetchMyClasses() async throws -> [ClassRoom] {
    []
  }

  func fetchRecommendedBattles(
    filter _: ClassTopicFilter
  ) async throws -> [ClassBattleSummary] {
    []
  }

  func createClass(_: ClassCreation) async throws -> ClassRoom {
    .mockJoinable
  }

  func fetchClass(joinCode: String) async throws -> ClassRoom {
    try await fetchClass(joinCode)
  }

  func joinClass(joinCode: String, nickname: String) async throws -> ClassRoom {
    try await joinClass(joinCode, nickname)
  }

  func updateDeadline(id _: Int, deadline _: Date) async throws -> ClassRoom {
    .mockJoinable
  }

  func deleteClass(id _: Int) async throws {}

  func leaveClass(id _: Int) async throws {}

  func fetchReport(roomID _: Int) async throws -> ClassReport? {
    nil
  }

  func fetchOwnerDashboard(roomID _: Int) async throws -> ClassOwnerDashboardData? {
    nil
  }
}
