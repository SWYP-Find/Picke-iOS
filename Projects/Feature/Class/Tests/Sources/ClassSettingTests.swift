@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct ClassSettingTests {
  private let battle = ClassBattleSummary.mocks[0]
  private let deadline = Date(timeIntervalSince1970: 1_800_000_000)

  @Test
  func 클래스명이_비어있으면_만들기를_누를_수_없다() {
    var state = ClassSettingFeature.State(battle: battle, deadline: deadline)
    state.name = "   "
    #expect(state.canCreate == false)

    state.name = "2학년 3반"
    #expect(state.canCreate)
  }

  @Test
  func 마감일을_끄면_마감일_없이_클래스를_만든다() {
    var state = ClassSettingFeature.State(battle: battle, deadline: deadline)
    state.name = " 2학년 3반 "
    state.isDeadlineEnabled = false

    #expect(state.creation?.name == "2학년 3반")
    #expect(state.creation?.deadline == .distantFuture)
    #expect(state.creation?.battleId == battle.id)
  }

  @Test
  func 클래스를_만들면_생성_델리게이트를_보낸다() async throws {
    var state = ClassSettingFeature.State(battle: battle, deadline: deadline)
    state.name = "2학년 3반"
    let store = TestStore(initialState: state) {
      ClassSettingFeature()
    }
    store.exhaustivity = .off

    await store.send(.view(.createTapped))
    try await store.receive(\.async, .create(#require(state.creation))) {
      $0.isLoading = true
    }
    await store.receive(\.inner.created) {
      $0.isLoading = false
    }
    await store.receive(\.delegate.created)
  }

  @Test
  func AI_질문_클래스_만들기는_안내를_표시하고_생성하지_않는다() async {
    var state = ClassSettingFeature.State(aiQuestion: ClassAIQuestion.examples[0], filter: .init(), deadline: deadline)
    state.name = "2학년 3반"
    #expect(state.creation == nil)

    let store = TestStore(initialState: state) {
      ClassSettingFeature()
    }
    await store.send(.view(.createTapped)) {
      $0.unavailableNotice = .init()
    }
    await store.send(.unavailableNotice(.presented(.dismissTapped))) {
      $0.unavailableNotice = nil
    }
  }

  @Test
  func AI_질문_필드를_목_배틀과_생성_요청으로_변환한다() throws {
    let question = ClassAIQuestion.examples[0]
    var state = ClassSettingFeature.State(
      aiQuestion: question,
      filter: .init(level: .high, category: .literature),
      deadline: deadline
    )
    state.name = " 2학년 3반 "
    state.requiresComment = true
    let battle = try #require(state.aiBattle)
    #expect(battle.id == -question.id)
    #expect(battle.title == question.title)
    #expect(battle.summary == question.summary)
    #expect(battle.optionATitle == question.optionATitle)
    #expect(battle.philosopherA == question.optionADescription)
    #expect(battle.optionBTitle == question.optionBTitle)
    #expect(battle.philosopherB == question.optionBDescription)
    #expect(battle.category == .literature)
    #expect(battle.level == .high)
    #expect(battle.audioDuration == 0)
    #expect(battle.viewCount == 0)
    #expect(state.aiCreation?.name == "2학년 3반")
    #expect(state.aiCreation?.battleId == battle.id)
    #expect(state.aiCreation?.requiresComment == true)
  }

  @Test
  func 목_저장소가_있을_때_AI_클래스를_만들고_라이브_유스케이스는_호출하지_않는다() async throws {
    let repository = MockClassRepository(rooms: [], availableRooms: [])
    var state = ClassSettingFeature.State(
      aiQuestion: ClassAIQuestion.examples[1],
      filter: .init(level: .adult, category: .society),
      deadline: deadline
    )
    state.name = "AI 토론"
    let creation = try #require(state.aiCreation)
    let battle = try #require(state.aiBattle)
    let store = TestStore(initialState: state) {
      ClassSettingFeature()
    } withDependencies: {
      $0.classMockRepository = repository
      $0.classUseCase = FailingClassUseCase()
    }
    store.exhaustivity = .off

    await store.send(.view(.createTapped))
    try await store.receive(\.async, .createAI(creation, battle)) {
      $0.isLoading = true
    }
    await store.receive(\.inner.created) {
      $0.isLoading = false
    }
    await store.receive(\.delegate.created)
    let rooms = try await repository.fetchMyClasses()
    #expect(rooms.count == 1)
    #expect(rooms[0].battle == battle)
  }
}

private struct FailingClassUseCase: ClassInterface {
  func fetchMyClasses() async throws -> [ClassRoom] {
    fatalError("live use case called")
  }

  func fetchRecommendedBattles(filter _: ClassTopicFilter) async throws
    -> [ClassBattleSummary]
  {
    fatalError("live use case called")
  }

  func createClass(_: ClassCreation) async throws -> ClassRoom {
    fatalError("live use case called")
  }

  func fetchClass(joinCode _: String) async throws -> ClassRoom {
    fatalError("live use case called")
  }

  func joinClass(joinCode _: String, nickname _: String) async throws -> ClassRoom {
    fatalError("live use case called")
  }

  func updateDeadline(id _: Int, deadline _: Date) async throws -> ClassRoom {
    fatalError("live use case called")
  }

  func deleteClass(id _: Int) async throws {
    fatalError("live use case called")
  }
}
