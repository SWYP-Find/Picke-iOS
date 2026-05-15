//
//  HomeFeature.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//

import ComposableArchitecture
import Entity
import Foundation
import LogMacro

@Reducer
public struct HomeFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var heroes: [HeroBattle]
    public var heroIndex: Int
    public var hotBattles: [HotBattle]
    public var bestBattles: [BestBattle]
    public var quiz: QuizQuestion
    public var vote: VoteQuestion
    public var newBattles: [NewBattle]

    public init(
      heroes: [HeroBattle] = HeroBattle.mocks,
      heroIndex: Int = 0,
      hotBattles: [HotBattle] = HotBattle.mocks,
      bestBattles: [BestBattle] = BestBattle.mocks,
      quiz: QuizQuestion = .mock,
      vote: VoteQuestion = .mock,
      newBattles: [NewBattle] = NewBattle.mocks
    ) {
      self.heroes = heroes
      self.heroIndex = heroIndex
      self.hotBattles = hotBattles
      self.bestBattles = bestBattles
      self.quiz = quiz
      self.vote = vote
      self.newBattles = newBattles
    }

    /// 캐러셀이 현재 보여주는 hero (position/total 은 인덱스 기준으로 항상 새로 계산).
    public var currentHero: HeroBattle {
      let safe = max(0, min(heroIndex, heroes.count - 1))
      let raw = heroes[safe]
      return HeroBattle(
        id: raw.id,
        badge: raw.badge,
        position: safe + 1,
        total: heroes.count,
        optionA: raw.optionA,
        optionB: raw.optionB,
        title: raw.title,
        subtitle: raw.subtitle,
        tags: raw.tags,
        viewCount: raw.viewCount
      )
    }
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
    case seeMoreTapped(Section)
  }

  public enum Section: Equatable {
    case hotBattles
    case bestBattles
    case todayPicke
    case newBattles
  }

  public enum AsyncAction: Equatable {}
  public enum InnerAction: Equatable {}
  public enum DelegateAction: Equatable {}

  nonisolated enum CancelID: Hashable {}

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        .none
      case let .view(viewAction):
        handleViewAction(state: &state, action: viewAction)
      case .async, .inner, .delegate:
        .none
      }
    }
  }
}

extension HomeFeature {
  private func handleViewAction(
    state _: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear, .seeMoreTapped:
      .none
    }
  }
}
