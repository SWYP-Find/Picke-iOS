@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Testing

@MainActor
struct ClassRecommendTests {
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
    #expect(state.shouldShowSkeleton)

    state.isLoading = false
    state.loadFailed = true
    #expect(state.shouldShowSkeleton == false)
    #expect(state.shouldShowLoadError)

    state.battles = ClassBattleSummary.mocks
    #expect(state.shouldShowLoadError == false)
  }
}
