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
  func 조건_수정은_닫고_다시_추천은_질문을_회전하며_선택을_해제한다() async {
    let editStore = TestStore(initialState: ClassRecommendFeature.State(filter: .init(), mode: .aiQuestions)) {
      ClassRecommendFeature()
    }
    await editStore.send(.view(.editConditionTapped))
    await editStore.receive(\.delegate, .dismiss)

    var state = ClassRecommendFeature.State(filter: .init(), mode: .aiQuestions)
    state.questions = ClassAIQuestion.examples
    state.selectedQuestionId = ClassAIQuestion.examples.first?.id
    let recommendStore = TestStore(initialState: state) { ClassRecommendFeature() }
    await recommendStore.send(.view(.recommendAgainTapped)) {
      $0.questions = Array(ClassAIQuestion.examples.dropFirst()) + ClassAIQuestion.examples.prefix(1)
      $0.selectedQuestionId = nil
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
    }
  }

  @Test
  func 배틀을_선택하고_선택하기를_누르면_선택_델리게이트를_보낸다() async {
    let battle = ClassBattleSummary.mocks[0]
    var state = ClassRecommendFeature.State(filter: .init())
    state.battles = [battle]
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
  func 선택한_배틀을_다시_누르면_선택이_해제된다() async {
    var state = ClassRecommendFeature.State(filter: .init())
    state.battles = ClassBattleSummary.mocks
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
    state.isLoading = true
    #expect(state.viewState == .loading)

    state.isLoading = false
    state.loadFailed = true
    #expect(state.viewState == .error)

    state.battles = ClassBattleSummary.mocks
    #expect(state.viewState == .loaded)
  }

  @Test
  func AI_예시_질문을_선택하면_설정_경로로_전달한다() async {
    let filter = ClassTopicFilter(keyword: "뫼르소", level: .high, category: .literature)
    let store = TestStore(initialState: ClassRecommendFeature.State(filter: filter, mode: .aiQuestions)) {
      ClassRecommendFeature()
    }

    await store.send(.view(.onAppear)) {
      $0.questions = ClassAIQuestion.examples
    }
    await store.send(.view(.questionTapped(1))) {
      $0.selectedQuestionId = 1
    }
    await store.send(.view(.selectTapped))
    await store.receive(\.delegate, .selectAIQuestion(ClassAIQuestion.examples[0], filter))
  }
}
