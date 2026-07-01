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

    /// 종 아이콘 빨간점 — 미읽음 알림 존재 여부 (알림 화면과 전역 공유).
    @Shared(.appStorage("HasUnreadNotification")) public var hasUnreadNotification: Bool = false
    /// QA-47: 모두읽음 직후, 서버 newNotice 가 아직 미읽음으로 지연될 때 빨간점이 되살아나는 것을 막는 가드.
    @Shared(.appStorage("NotificationReadAllPending")) public var readAllPending: Bool = false

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
    case notificationTapped
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
    /// 알림(종) 아이콘 → 알림받기 화면.
    case openNotification
  }

  nonisolated enum CancelID: Hashable {
    case fetchHome
  }

  @Dependency(\.homeUseCase) private var homeUseCase
  @Dependency(\.analyticsUseCase) private var analyticsUseCase

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
      analyticsUseCase.track(.screenView(screen: .home, referrer: nil))
      guard !state.hasLoadedHome, !state.isLoading else { return .none }
      return .send(.async(.fetchHome))

    case .pullToRefresh:
      guard !state.isLoading else { return .none }
      return .send(.async(.fetchHome))

    case .seeMoreTapped:
      analyticsUseCase.track(.uiAction(action: .homeMore, screen: .home))
      return .send(.delegate(.moveToExplore))

    case let .voteTapped(question):
      analyticsUseCase.track(.contentAction(ContentActionData(
        action: .voteCardTap,
        contentID: "\(question.battleId)",
        section: "vote"
      )))
      return .send(.delegate(.presentPreVote(battleId: question.battleId)))

    case let .heroTapped(battle):
      analyticsUseCase.track(.contentAction(ContentActionData(action: .heroTap, contentID: "\(battle.battleId)")))
      return .send(.delegate(.presentPreVote(battleId: battle.battleId)))

    case let .hotBattleTapped(battle):
      analyticsUseCase.track(.contentAction(ContentActionData(
        action: .battleCardTap,
        contentID: "\(battle.battleId)",
        section: "hot"
      )))
      return .send(.delegate(.presentPreVote(battleId: battle.battleId)))

    case let .bestBattleTapped(battle):
      analyticsUseCase.track(.contentAction(ContentActionData(
        action: .battleCardTap,
        contentID: "\(battle.battleId)",
        section: "best"
      )))
      return .send(.delegate(.presentPreVote(battleId: battle.battleId)))

    case let .newBattleTapped(battle):
      analyticsUseCase.track(.contentAction(ContentActionData(
        action: .newBattleTap,
        contentID: "\(battle.battleId)",
        section: "new"
      )))
      return .send(.delegate(.presentPreVote(battleId: battle.battleId)))

    case .notificationTapped:
      analyticsUseCase.track(.uiAction(action: .homeNotification, screen: .home))
      return .send(.delegate(.openNotification))
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
        // QA-47: 홈 진입/재진입 시 서버의 미읽음 여부를 종 아이콘 빨간점(전역 공유 플래그)에 반영.
        // 단, 방금 모두읽음(readAllPending) 했는데 서버가 아직 미읽음으로 지연되면 되살리지 않는다.
        // 서버가 읽음을 반영(newNotice=false)하면 점을 끄고 pending 을 해제한다.
        if home.newNotice {
          if !state.readAllPending {
            state.$hasUnreadNotification.withLock { $0 = true }
          }
        } else {
          state.$hasUnreadNotification.withLock { $0 = false }
          state.$readAllPending.withLock { $0 = false }
        }
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
    case .presentPreVote, .moveToExplore, .openNotification:
      return .none
    }
  }
}
