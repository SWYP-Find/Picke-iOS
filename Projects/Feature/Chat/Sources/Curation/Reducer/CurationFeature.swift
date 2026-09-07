//
//  CurationFeature.swift
//  Chat
//

import Foundation

import BattleDomainInterface
import ComposableArchitecture
import PickeAnalyticsInterface

@Reducer
public struct CurationFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var battleId: Int
    public var isLoading: Bool = false
    public var battles: [RecommendedBattle] = []

    public init(battleId: Int = 0) {
      self.battleId = battleId
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
    case backButtonTapped
    case closeButtonTapped
    case battleTapped(battleId: Int)
    case adNativeClicked
  }

  public enum AsyncAction: Equatable {
    case fetchRecommendations
  }

  public enum InnerAction: Equatable {
    case recommendationsResponse(Result<RecommendedBattlePage, BattleError>)
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case close
    case openBattle(battleId: Int)
  }

  nonisolated enum CancelID: Hashable {
    case fetchRecommendations
  }

  @Dependency(\.battleUseCase) private var battleUseCase
  @Dependency(\.analyticsUseCase) private var analyticsUseCase

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

extension CurationFeature {
  private func handleViewAction(
    state _: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      analyticsUseCase.track(.screenView(screen: .curation, referrer: nil))
      return .send(.async(.fetchRecommendations))

    case .backButtonTapped:
      return .send(.delegate(.dismiss))

    case .closeButtonTapped:
      analyticsUseCase.track(.contentAction(ContentActionData(action: .battleRecommendClose)))
      return .send(.delegate(.close))

    case let .battleTapped(battleId):
      analyticsUseCase.track(.uiAction(action: .curationBattle, screen: .curation))
      return .send(.delegate(.openBattle(battleId: battleId)))

    case .adNativeClicked:
      analyticsUseCase.track(.adClick(AdClickData(placement: .curation, format: .native, unit: "ADFIT_NATIVE_2_1")))
      return .none
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetchRecommendations:
      state.isLoading = true
      let battleId = state.battleId
      return .run { [useCase = battleUseCase] send in
        let result = await Result {
          try await useCase.fetchRecommendedBattles(battleId: battleId)
        }
        .mapError(BattleError.from)
        return await send(.inner(.recommendationsResponse(result)))
      }
      .cancellable(id: CancelID.fetchRecommendations, cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .recommendationsResponse(result):
      state.isLoading = false
      switch result {
      case let .success(page):
        state.battles = page.items
      case let .failure(error):
        Log.error("[CurationFeature] recommendations failed: \(error.localizedDescription)")
        state.battles = []
      }
      return .none
    }
  }
}
