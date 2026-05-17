//
//  PreVoteFeature.swift
//  Home
//
//  Created by Wonji Suh on 5/16/26.
//

import Foundation

import ComposableArchitecture
import Entity

@Reducer
public struct PreVoteFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var battle: PreVoteBattle = .mock
    public var selectedSide: PhilosopherAvatar?
    public var isSubmitting: Bool = false
    public var shareItem: ShareItem?

    public var isPrimaryButtonEnabled: Bool {
      selectedSide != nil && !isSubmitting
    }

    public init() {}
  }

  /// 공유 시트 트리거. `.sheet(item:)` 에 바로 바인딩.
  public struct ShareItem: Equatable, Identifiable {
    public let id: UUID
    public let items: [String]

    public init(id: UUID = UUID(), items: [String]) {
      self.id = id
      self.items = items
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
    case backButtonTapped
    case shareTapped
    case optionTapped(PhilosopherAvatar)
    case primaryButtonTapped
  }

  public enum AsyncAction: Equatable {}
  public enum InnerAction: Equatable {}

  public enum DelegateAction: Equatable {
    case dismiss
    case submit(battleId: Int, side: PhilosopherAvatar)
  }

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

extension PreVoteFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backButtonTapped:
      return .send(.delegate(.dismiss))

    case .shareTapped:
      state.shareItem = ShareItem(
        items: [
          "\(state.battle.titleLine1) \(state.battle.titleLine2)",
          "https://picke.store/battle/\(state.battle.battleId)",
        ]
      )
      return .none

    case let .optionTapped(side):
      state.selectedSide = (state.selectedSide == side) ? nil : side
      return .none

    case .primaryButtonTapped:
      guard let side = state.selectedSide else { return .none }
      state.isSubmitting = true
      return .send(.delegate(.submit(battleId: state.battle.battleId, side: side)))
    }
  }

  private func handleAsyncAction(
    state _: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {}
  }

  private func handleInnerAction(
    state _: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {}
  }

  private func handleDelegateAction(
    state _: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
    case .dismiss, .submit:
      .none
    }
  }
}
