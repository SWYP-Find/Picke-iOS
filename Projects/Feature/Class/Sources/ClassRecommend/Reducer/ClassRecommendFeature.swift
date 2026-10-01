//
//  ClassRecommendFeature.swift
//  Class
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation

@Reducer
public struct ClassRecommendFeature {
  @Dependency(\.classUseCase) private var classUseCase

  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var filter: ClassTopicFilter
    public var battles: [ClassBattleSummary] = []
    public var selectedBattleId: Int?
    public var isLoading = false
    public var loadFailed = false

    public init(filter: ClassTopicFilter) {
      self.filter = filter
    }

    public var conditionTitles: [String] {
      [filter.level.title, filter.category?.title].compactMap(\.self)
    }

    public var resultTitle: String {
      "추천 결과 \(battles.count)개"
    }

    public var selectedBattle: ClassBattleSummary? {
      battles.first { $0.id == selectedBattleId }
    }

    public var canSelect: Bool {
      selectedBattle != nil
    }

    public var shouldShowSkeleton: Bool {
      isLoading && battles.isEmpty
    }

    /// 로드 실패 & 표시할 배틀이 없을 때 스켈레톤 대신 오류를 노출한다.
    public var shouldShowLoadError: Bool {
      loadFailed && battles.isEmpty
    }
  }

  public enum Action: ViewAction {
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case onAppear
    case retryTapped
    case backTapped
    case editConditionTapped
    case battleTapped(Int)
    case previewTapped(Int)
    case selectTapped
  }

  public enum AsyncAction: Equatable {
    case fetch(ClassTopicFilter)
  }

  public enum InnerAction: Equatable {
    case battles(Result<[ClassBattleSummary], ClassError>)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case select(ClassBattleSummary)
  }

  nonisolated enum CancelID: Hashable {
    case fetch
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)

      case let .async(asyncAction):
        return handleAsyncAction(state: &state, action: asyncAction)

      case let .inner(innerAction):
        return handleInnerAction(state: &state, action: innerAction)

      case .delegate:
        return .none
      }
    }
  }
}

extension ClassRecommendFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      guard state.battles.isEmpty else { return .none }
      return .send(.async(.fetch(state.filter)))

    case .retryTapped:
      return .send(.async(.fetch(state.filter)))

    case .backTapped, .editConditionTapped:
      return .send(.delegate(.dismiss))

    case let .battleTapped(id):
      state.selectedBattleId = state.selectedBattleId == id ? nil : id
      return .none

    case .previewTapped:
      return .none

    case .selectTapped:
      guard let battle = state.selectedBattle else { return .none }
      return .send(.delegate(.select(battle)))
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case let .fetch(filter):
      state.isLoading = true
      state.loadFailed = false
      return .run { [classUseCase] send in
        let result = await Result {
          try await classUseCase.fetchRecommendedBattles(filter: filter)
        }
        .mapError(ClassError.from)
        await send(.inner(.battles(result)))
      }
      .cancellable(id: CancelID.fetch, cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .battles(result):
      state.isLoading = false
      switch result {
      case let .success(battles):
        state.battles = battles
      case .failure:
        state.loadFailed = true
      }
      return .none
    }
  }
}
