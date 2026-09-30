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
  }

  public enum Action: ViewAction {
    case view(View)
    case response(Response)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case onAppear
    case backTapped
    case editConditionTapped
    case battleTapped(Int)
    case previewTapped(Int)
    case selectTapped
  }

  @CasePathable
  public enum Response: Equatable {
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

      case let .response(response):
        return handleResponse(state: &state, response: response)

      case .delegate:
        return .none
      }
    }
  }
}

private extension ClassRecommendFeature {
  func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      guard state.battles.isEmpty else { return .none }
      state.isLoading = true
      return .run { [classUseCase, filter = state.filter] send in
        let result = await Result {
          try await classUseCase.fetchRecommendedBattles(filter: filter)
        }
        .mapError(ClassError.from)
        await send(.response(.battles(result)))
      }
      .cancellable(id: CancelID.fetch, cancelInFlight: true)

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

  func handleResponse(
    state: inout State,
    response: Response
  ) -> Effect<Action> {
    switch response {
    case let .battles(result):
      state.isLoading = false
      if case let .success(battles) = result {
        state.battles = battles
      }
      return .none
    }
  }
}
