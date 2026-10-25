//
//  ClassSettingTests.swift
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
  func 운영자_참여_선택은_일반과_AI_클래스_생성_요청에_전달된다() {
    var regular = ClassSettingFeature.State(battle: battle, deadline: deadline)
    regular.name = "일반 토론"
    #expect(regular.creation?.ownerParticipates == false)
    regular.ownerParticipates = true
    #expect(regular.creation?.ownerParticipates == true)

    var ai = ClassSettingFeature.State()
    ai.aiQuestion = ClassAIQuestion(version: topicVersion)
    ai.topicVersionID = topicVersion.id
    ai.filter = .init()
    ai.deadline = deadline
    ai.name = "AI 토론"
    #expect(ai.aiCreation?.ownerParticipates == false)
    ai.ownerParticipates = true
    #expect(ai.aiCreation?.ownerParticipates == true)
  }

  @Test
  func 클래스를_만들면_생성_델리게이트를_보낸다() async throws {
    var state = ClassSettingFeature.State(battle: battle, deadline: deadline)
    state.name = "2학년 3반"
    let store = TestStore(initialState: state) {
      ClassSettingFeature()
    } withDependencies: {
      $0.date.now = deadline.addingTimeInterval(-3600)
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
    } withDependencies: {
      $0.date.now = deadline.addingTimeInterval(-3600)
    }
    await store.send(.view(.createTapped)) {
      $0.unavailableNotice = .init()
    }
    await store.send(.unavailableNotice(.presented(.dismissTapped))) {
      $0.unavailableNotice = nil
    }
  }

  @Test
  func 지난_마감일은_생성_IO_전에_차단한다() async {
    var state = ClassSettingFeature.State(battle: battle, deadline: deadline)
    state.name = "토론 클래스"
    let store = TestStore(initialState: state) {
      ClassSettingFeature()
    } withDependencies: {
      $0.date.now = deadline.addingTimeInterval(1)
      $0.classUseCase = FailingClassUseCase()
    }

    await store.send(.view(.createTapped)) {
      $0.deadlineValidationMessage = "현재 이후 시간을 선택해 주세요."
    }
    await store.finish()
  }

  @Test
  func 마감일이_꺼져_있으면_지난_날짜여도_생성_단계로_진행한다() async {
    var state = ClassSettingFeature.State(
      aiQuestion: ClassAIQuestion.examples[0],
      filter: .init(),
      deadline: deadline
    )
    state.name = "AI 토론"
    state.isDeadlineEnabled = false
    let store = TestStore(initialState: state) {
      ClassSettingFeature()
    } withDependencies: {
      $0.date.now = deadline.addingTimeInterval(1)
      $0.classMockRepository = nil
      $0.classUseCase = FailingClassUseCase()
    }

    await store.send(.view(.createTapped)) {
      $0.unavailableNotice = .init()
    }
    await store.finish()
  }

  @Test(arguments: [true, false])
  func 마감일_편집은_활성화되고_저장중이_아닐_때만_위임한다(enabled: Bool) async {
    var state = ClassSettingFeature.State(battle: battle, deadline: deadline)
    state.isDeadlineEnabled = enabled
    let store = TestStore(initialState: state) { ClassSettingFeature() }
    await store.send(.view(.deadlineFieldTapped))
    if enabled {
      await store.receive(\.delegate.editDeadline, state.instanceID)
    }
    await store.send(.binding(.set(\.isLoading, true))) {
      $0.isLoading = true
    }
    await store.send(.view(.deadlineFieldTapped))
    await store.finish()
  }

  @Test
  func AI_질문_필드를_목_배틀과_생성_요청으로_변환한다() throws {
    let example = ClassAIQuestion.examples[0]
    let question = ClassAIQuestion(
      id: example.id,
      category: "도덕",
      title: example.title,
      summary: example.summary,
      optionATitle: example.optionATitle,
      optionADescription: example.optionADescription,
      philosopherAName: example.philosopherAName,
      optionBTitle: example.optionBTitle,
      optionBDescription: example.optionBDescription,
      philosopherBName: example.philosopherBName
    )
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
    #expect(battle.philosopherA == "사르트르")
    #expect(battle.optionADescription == "사회적 공감도 중요하다")
    #expect(battle.optionBTitle == question.optionBTitle)
    #expect(battle.philosopherB == "플라톤")
    #expect(battle.optionBDescription == "연령과 교정 가능성 고려")
    #expect(battle.category == .literature)
    #expect(battle.categoryDisplayTitle == "도덕")
    #expect(battle.level == .high)
    #expect(battle.audioDuration == 0)
    #expect(battle.viewCount == 0)
    #expect(state.aiCreation == nil)
  }

  @Test
  func 이름이_없는_AI_선택지의_설명과_카테고리를_따로_보존한다() throws {
    let example = ClassAIQuestion.examples[1]
    let question = ClassAIQuestion(
      id: example.id,
      category: "범죄",
      title: example.title,
      summary: example.summary,
      optionATitle: example.optionATitle,
      optionADescription: example.optionADescription,
      philosopherAName: example.philosopherAName,
      optionBTitle: example.optionBTitle,
      optionBDescription: example.optionBDescription,
      philosopherBName: example.philosopherBName
    )
    let state = ClassSettingFeature.State(
      aiQuestion: question,
      filter: .init(level: .adult, category: .society),
      deadline: deadline
    )
    let battle = try #require(state.aiBattle)

    #expect(battle.category == .society)
    #expect(battle.categoryDisplayTitle == "범죄")
    #expect(battle.philosopherA == "A 입장")
    #expect(battle.optionADescription == question.optionADescription)
    #expect(battle.philosopherB == "B 입장")
    #expect(battle.optionBDescription == question.optionBDescription)
    #expect(
      ClassBattleSummary.mocks[0].categoryDisplayTitle
        == ClassBattleSummary.mocks[0].category.title
    )
    #expect(ClassBattleSummary.mocks[0].optionADescription == nil)
  }

  @Test
  func 목_저장소가_있어도_서버_주제_버전이_없으면_AI_클래스를_만들지_않는다() async {
    let repository = MockClassRepository(rooms: [], availableRooms: [])
    var state = ClassSettingFeature.State(
      aiQuestion: ClassAIQuestion.examples[1],
      filter: .init(level: .adult, category: .society),
      deadline: deadline
    )
    state.name = "AI 토론"
    let store = TestStore(initialState: state) {
      ClassSettingFeature()
    } withDependencies: {
      $0.date.now = deadline.addingTimeInterval(-3600)
      $0.classMockRepository = repository
      $0.classUseCase = FailingClassUseCase()
    }
    await store.send(.view(.createTapped)) {
      $0.unavailableNotice = .init()
    }
    await store.finish()
  }

  @Test
  func 서버_주제_버전으로_AI_클래스_생성_요청을_만든다() {
    var state = ClassSettingFeature.State()
    state.aiQuestion = ClassAIQuestion(version: topicVersion)
    state.topicVersionID = topicVersion.id
    state.filter = .init()
    state.deadline = deadline
    state.name = "AI 토론"
    state.requiresComment = true

    #expect(state.creation?.battleId == nil)
    #expect(state.creation?.topicVersionId == 12)
    #expect(state.creation?.requiresComment == true)
    #expect(state.aiQuestion?.title == topicVersion.question)
  }

  private var topicVersion: ClassTopicVersion {
    ClassTopicVersion(
      id: 12,
      draftID: 7,
      versionNo: 1,
      source: "CANDIDATE",
      question: "감정을 표현해야 하나요?",
      description: "표현의 자유를 토론해요.",
      category: "문학",
      difficulty: "INTERMEDIATE",
      options: [
        .init(position: "A", label: "해야 한다", rationale: "공감", philosopher: "KANT", philosopherName: "칸트", philosopherImageKey: nil),
        .init(position: "B", label: "선택이다", rationale: "자유", philosopher: nil, philosopherName: nil, philosopherImageKey: nil),
      ]
    )
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

  func leaveClass(id _: Int) async throws {
    fatalError("live use case called")
  }

  func fetchReport(roomID _: Int) async throws -> ClassReport? {
    fatalError("live use case called")
  }

  func fetchOwnerDashboard(roomID _: Int) async throws -> ClassOwnerDashboardData? {
    fatalError("live use case called")
  }
}
