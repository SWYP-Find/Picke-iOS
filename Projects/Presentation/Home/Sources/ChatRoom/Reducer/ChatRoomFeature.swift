//
//  ChatRoomFeature.swift
//  Home
//
//  Created by Wonji Suh on 5/19/26.
//

import Foundation

import ComposableArchitecture
import Entity
import LogMacro

@Reducer
public struct ChatRoomFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var bundle: ChatRoomBundle = .mock
    public var isPlaying: Bool = false
    public var currentTime: TimeInterval = 0
    public var battleId: Int = 0

    public var totalDuration: TimeInterval { bundle.totalDuration }
    public var battleTitle: String { bundle.battleTitle }
    public var messages: [ChatMessage] { bundle.messages }

    public init(battleId: Int = 0) {
      self.battleId = battleId
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
    case backButtonTapped
    case refreshTapped
    case togglePlayTapped
    case seekBackwardTapped
    case seekForwardTapped
    case scrub(TimeInterval)
  }

  public enum AsyncAction: Equatable {}
  public enum InnerAction: Equatable {}

  public enum DelegateAction: Equatable {
    case dismiss
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

extension ChatRoomFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      return .none
    case .backButtonTapped:
      return .send(.delegate(.dismiss))
    case .refreshTapped:
      state.currentTime = 0
      state.isPlaying = false
      return .none
    case .togglePlayTapped:
      state.isPlaying.toggle()
      return .none
    case .seekBackwardTapped:
      state.currentTime = max(0, state.currentTime - 15)
      return .none
    case .seekForwardTapped:
      state.currentTime = min(state.totalDuration, state.currentTime + 15)
      return .none
    case let .scrub(time):
      state.currentTime = min(max(0, time), state.totalDuration)
      return .none
    }
  }

  private func handleAsyncAction(state _: inout State, action: AsyncAction) -> Effect<Action> {
    switch action {}
  }

  private func handleInnerAction(state _: inout State, action: InnerAction) -> Effect<Action> {
    switch action {}
  }

  private func handleDelegateAction(state _: inout State, action: DelegateAction) -> Effect<Action> {
    switch action {
    case .dismiss:
      .none
    }
  }
}
