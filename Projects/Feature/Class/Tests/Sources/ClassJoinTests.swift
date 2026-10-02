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
      $0.joinCode = " pk9t3s "
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
    await store.receive(\.inner, .joined(.success(room))) {
      $0.preview = nil
      $0.isLoading = false
    }
    await store.receive(\.delegate.joined)
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

    await store.send(.binding(.set(\.joinCode, "INVALID"))) {
      $0.joinCode = "INVALID"
    }
    await store.send(.view(.findTapped))
    await store.receive(\.async, .find("INVALID")) {
      $0.isLoading = true
    }
    await store.receive(\.inner, .found(.failure(.invalidCode))) {
      $0.isLoading = false
      $0.errorMessage = "참여 코드를 다시 확인해 주세요."
    }
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
}
