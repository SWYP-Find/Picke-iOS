//
//  HomeFeature.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//

import ComposableArchitecture
import DomainInterface
import Entity
import Foundation
import LogMacro
import UseCase

@Reducer
public struct HomeFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var isLoading: Bool = false
    public var hasLoadedHome: Bool = false
    public var newNotice: Bool = false
    public var heroes: [HeroBattle] = []
    public var heroIndex: Int = 0
    public var hotBattles: [HotBattle] = []
    public var bestBattles: [BestBattle] = []
    public var quizzes: [QuizQuestion] = []
    public var votes: [VoteQuestion] = []
    public var newBattles: [NewBattle] = []

    public var currentQuiz: QuizQuestion? { quizzes.first }
    public var currentVote: VoteQuestion? { votes.first }

    public init() {}
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case onAppear
    case pullToRefresh
    case seeMoreTapped(Section)
    case voteTapped(VoteQuestion)
    case heroTapped(HeroBattle)
    case hotBattleTapped(HotBattle)
    case bestBattleTapped(BestBattle)
    case newBattleTapped(NewBattle)
  }

  public enum Section: Equatable {
    case hotBattles
    case bestBattles
    case todayPicke
    case newBattles
  }

  public enum AsyncAction: Equatable {
    case fetchHome
  }

  public enum InnerAction: Equatable {
    case homeResponse(Result<HomeBundle, AuthError>)
  }

  public enum DelegateAction: Equatable {
    case presentPreVote(battleId: Int)
    /// "더보기" → 탐색 탭으로 이동.
    case moveToExplore
  }

  nonisolated enum CancelID: Hashable {
    case fetchHome
  }

  @Dependency(\.homeUseCase) private var homeUseCase

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        .none
      case let .view(viewAction):
        handleViewAction(state: &state, action: viewAction)
      case let .async(asyncAction):
        handleAsyncAction(state: &state, action: asyncAction)
      case let .inner(innerAction):
        handleInnerAction(state: &state, action: innerAction)
      case let .delegate(delegateAction):
        handleDelegateAction(state: &state, action: delegateAction)
      }
    }
  }
}

extension HomeFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      guard !state.hasLoadedHome, !state.isLoading else { return .none }
      return .send(.async(.fetchHome))

    case .pullToRefresh:
      guard !state.isLoading else { return .none }
      return .send(.async(.fetchHome))

    case .seeMoreTapped:
      return .send(.delegate(.moveToExplore))

    case let .voteTapped(question):
      return .send(.delegate(.presentPreVote(battleId: question.battleId)))

    case let .heroTapped(battle):
      return .send(.delegate(.presentPreVote(battleId: battle.battleId)))

    case let .hotBattleTapped(battle):
      return .send(.delegate(.presentPreVote(battleId: battle.battleId)))

    case let .bestBattleTapped(battle):
      return .send(.delegate(.presentPreVote(battleId: battle.battleId)))

    case let .newBattleTapped(battle):
      return .send(.delegate(.presentPreVote(battleId: battle.battleId)))
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetchHome:
      state.isLoading = true
      return .run { [repository = homeUseCase] send in
        let result = await Result {
          try await repository.fetchHome()
        }
        .mapError(AuthError.from)
        return await send(.inner(.homeResponse(result)))
      }
      .cancellable(id: CancelID.fetchHome, cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .homeResponse(result):
      state.isLoading = false
      state.hasLoadedHome = true
      switch result {
      case let .success(bundle):
        let home = bundle.replacingEmptySectionsWithMocks
        state.newNotice = home.newNotice
        state.heroes = home.heroes
        state.heroIndex = 0
        state.hotBattles = home.hotBattles
        state.bestBattles = home.bestBattles
        state.quizzes = home.quizzes
        state.votes = home.votes
        state.newBattles = home.newBattles
      case let .failure(error):
        Log.error("[HomeFeature] fetchHome failed: \(error.localizedDescription)")
      }
      return .none
    }
  }

  private func handleDelegateAction(
    state _: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
    case .presentPreVote, .moveToExplore:
      .none
    }
  }
}
