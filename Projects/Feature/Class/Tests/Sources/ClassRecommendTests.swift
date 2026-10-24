//
//  ClassRecommendTests.swift
//  ClassTests
//
//  Created by Picke on 10/11/26.
//

@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Testing

@MainActor
struct ClassRecommendTests {
  @Test
  func 선택한_여러_카테고리를_조건_칩에_표시한다() {
    let state = ClassRecommendFeature.State(
      filter: .init(level: .middle, categories: [.society, .art, .philosophy])
    )

    #expect(state.conditionTitles == ["중등", "사회", "예술", "철학"])
  }

  @Test
  func 주제를_첫_조건으로_표시하고_중복된_철학_칩도_유지한다() {
    let state = ClassRecommendFeature.State(
      filter: .init(keyword: "  철학 \n", level: .middle, categories: [.philosophy, .society])
    )

    #expect(state.conditionTitles == ["철학", "중등", "철학", "사회"])
  }

  @Test
  func 추천_문구는_모드별_원본을_사용하고_선택_버튼은_같은_문구를_쓴다() {
    let existing = ClassRecommendFeature.State(filter: .init())
    let ai = ClassRecommendFeature.State(filter: .init(), mode: .aiQuestions)

    #expect(existing.introTitle == "주제에 어울리는\n배틀을 찾았어요")
    #expect(existing.introDescription == "미리 듣고 클래스에 사용할 배틀을 골라보세요")
    #expect(ai.introTitle == "AI가 주제에 어울리는\n질문을 만들었어요")
    #expect(ai.introDescription == "모임에서 나눌 질문을 골라 자유롭게 수정해보세요.")
    #expect(existing.selectButtonTitle == "배틀 선택하기")
    #expect(ai.selectButtonTitle == "배틀 선택하기")
  }

  @Test
  func 조건_수정은_화면을_닫고_다시_추천은_서버에_요청한다() async {
    let editStore = TestStore(initialState: ClassRecommendFeature.State(filter: .init(), mode: .aiQuestions)) {
      ClassRecommendFeature()
    }
    await editStore.send(.view(.editConditionTapped))
    await editStore.receive(\.delegate, .dismiss)

    var state = ClassRecommendFeature.State(filter: .init(), mode: .aiQuestions)
    state.draft = topicDraft
    state.questions = topicDraft.candidates.compactMap(ClassAIQuestion.init(candidate:))
    state.selectedQuestionId = 3
    state.viewState = .loaded
    let recommendStore = TestStore(initialState: state) { ClassRecommendFeature() } withDependencies: {
      $0.classTopicDraftUseCase = StubTopicDraftUseCase(draft: topicDraft, version: topicVersion)
    }
    await recommendStore.send(.view(.recommendAgainTapped)) {
      $0.selectedQuestionId = nil
    }
    await recommendStore.receive(\.async, .suggest(draftID: topicDraft.id)) {
      $0.isLoading = true
      $0.viewState = .loading
    }
    await recommendStore.receive(\.inner, .suggestionStarted(topicDraft))
    await recommendStore.receive(\.inner, .draft(.success(topicDraft))) {
      $0.isLoading = false
      $0.viewState = .loaded
    }
  }

  @Test
  func 화면이_뜨면_조건에_맞는_추천_배틀을_불러온다() async {
    let store = TestStore(initialState: ClassRecommendFeature.State(filter: .init(level: .middle))) {
      ClassRecommendFeature()
    }

    await store.send(.view(.onAppear))
    await store.receive(\.async, .fetch(.init(level: .middle))) {
      $0.isLoading = true
    }
    await store.receive(\.inner, .battles(.success(
      ClassBattleSummary.mocks.filter { $0.level == .middle }
    ))) {
      $0.isLoading = false
      $0.battles = ClassBattleSummary.mocks.filter { $0.level == .middle }
      $0.viewState = .loaded
    }
  }

  @Test
  func 배틀을_선택하고_선택하기를_누르면_선택_델리게이트를_보낸다() async {
    let battle = ClassBattleSummary.mocks[0]
    var state = ClassRecommendFeature.State(filter: .init())
    state.battles = [battle]
    state.viewState = .loaded
    let store = TestStore(initialState: state) {
      ClassRecommendFeature()
    }

    await store.send(.view(.battleTapped(battle.id))) {
      $0.selectedBattleId = battle.id
    }
    await store.send(.view(.selectTapped))
    await store.receive(\.delegate.select, battle)
  }

  @Test
  func 미리듣기는_배틀_선택을_바꾸지_않고_선택한_배틀을_전달한다() async {
    let battle = ClassBattleSummary.mocks[0]
    var state = ClassRecommendFeature.State(filter: .init())
    state.battles = [battle]
    state.viewState = .loaded
    let store = TestStore(initialState: state) { ClassRecommendFeature() }

    await store.send(.view(.previewTapped(battle.id)))
    await store.receive(\.delegate.previewRequested, battle)
    #expect(store.state.selectedBattleId == nil)
  }

  @Test
  func 선택한_배틀을_다시_누르면_선택이_해제된다() async {
    var state = ClassRecommendFeature.State(filter: .init())
    state.battles = ClassBattleSummary.mocks
    state.viewState = .loaded
    state.selectedBattleId = 101
    let store = TestStore(initialState: state) {
      ClassRecommendFeature()
    }

    await store.send(.view(.battleTapped(101))) {
      $0.selectedBattleId = nil
    }
    await store.send(.view(.selectTapped))
  }

  @Test
  func 로딩_중이고_배틀이_없으면_스켈레톤을_보여주고_실패하면_오류로_바꾼다() {
    var state = ClassRecommendFeature.State(filter: .init())
    #expect(state.viewState == .loading)
    state.isLoading = true
    #expect(state.viewState == .loading)

    state.viewState = .error
    #expect(state.viewState == .error)

    state.battles = ClassBattleSummary.mocks
    state.viewState = .loaded
    #expect(state.viewState == .loaded)
  }

  @Test
  func AI_질문과_빈_배틀_결과는_서버_조회_완료_후에만_표시된다() {
    let ai = ClassRecommendFeature.State(filter: .init(), mode: .aiQuestions)
    #expect(ai.questions.isEmpty)
    #expect(ai.viewState == .loading)

    var existing = ClassRecommendFeature.State(filter: .init())
    #expect(existing.viewState == .loading)
    existing.viewState = .empty
    #expect(existing.viewState == .empty)
  }

  @Test
  func 빈_추천_결과를_받아도_화면_재등장은_자동으로_재조회하지_않는다() async {
    let store = TestStore(initialState: ClassRecommendFeature.State(filter: .init())) {
      ClassRecommendFeature()
    }
    await store.send(.inner(.battles(.success([])))) {
      $0.viewState = .empty
    }
    #expect(store.state.viewState == .empty)
    await store.send(.view(.onAppear))
  }

  @Test
  func AI_후보를_선택하면_서버_주제_버전을_설정_경로로_전달한다() async {
    let filter = ClassTopicFilter(keyword: "뫼르소", level: .high, category: .literature)
    let store = TestStore(initialState: ClassRecommendFeature.State(filter: filter, mode: .aiQuestions)) {
      ClassRecommendFeature()
    } withDependencies: {
      $0.classTopicDraftUseCase = StubTopicDraftUseCase(draft: topicDraft, version: topicVersion)
    }

    await store.send(.view(.onAppear))
    await store.receive(\.async, .createDraft(filter)) {
      $0.isLoading = true
    }
    await store.receive(\.inner, .draftCreated(.success(topicDraft))) {
      $0.draft = topicDraft
    }
    await store.receive(\.async, .suggest(draftID: topicDraft.id))
    await store.receive(\.inner, .suggestionStarted(topicDraft))
    await store.receive(\.inner, .draft(.success(topicDraft))) {
      $0.isLoading = false
      $0.questions = topicDraft.candidates.compactMap(ClassAIQuestion.init(candidate:))
      $0.viewState = .loaded
    }
    await store.send(.view(.questionTapped(3))) {
      $0.selectedQuestionId = 3
    }
    await store.send(.view(.selectTapped))
    await store.receive(\.async, .select(draftID: topicDraft.id, batchNo: topicDraft.batchNo, candidateID: 3)) {
      $0.isLoading = true
    }
    await store.receive(\.inner, .selected(.success(topicVersion))) {
      $0.isLoading = false
    }
    await store.receive(\.delegate, .selectAIQuestion(topicVersion, filter))
  }

  private var topicDraft: ClassTopicDraft {
    ClassTopicDraft(
      id: 7,
      topicSeed: "뫼르소",
      difficulty: "INTERMEDIATE",
      categories: ["문학"],
      suggestStatus: "SUCCEEDED",
      clarificationMessage: nil,
      batchNo: 1,
      remainingSuggestions: 2,
      remainingValidations: 3,
      candidates: [
        ClassTopicCandidate(
          id: 3,
          question: "감정을 표현해야 하나요?",
          description: "표현의 자유를 토론해요.",
          category: "문학",
          difficulty: "INTERMEDIATE",
          options: [
            .init(label: "해야 한다", rationale: "공감", philosopher: "KANT"),
            .init(label: "선택이다", rationale: "자유", philosopher: nil),
          ]
        ),
      ],
      latestVersion: nil
    )
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

private struct StubTopicDraftUseCase: ClassTopicDraftInterface {
  let draft: ClassTopicDraft
  let version: ClassTopicVersion

  func create(filter: ClassTopicFilter) async throws -> ClassTopicDraft { draft }
  func fetch(id: Int) async throws -> ClassTopicDraft { draft }
  func suggest(id: Int, filter: ClassTopicFilter?) async throws -> ClassTopicDraft { draft }
  func select(draftID: Int, batchNo: Int, candidateID: Int) async throws -> ClassTopicVersion { version }
  func validate(draftID: Int, baseVersionID: Int, candidate: ClassTopicCandidate) async throws -> ClassTopicValidation {
    ClassTopicValidation(valid: true, issues: [], validatedTopicVersionID: version.id, remainingValidations: 2, version: version)
  }
}
