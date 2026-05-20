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
    /// 한 번 끝까지 재생되어야 시킹(드래그) 허용
    public var hasFinishedListening: Bool = false

    public var totalDuration: TimeInterval { bundle.totalDuration }
    public var battleTitle: String { bundle.battleTitle }
    public var messages: [ChatMessage] { bundle.messages }
    public var canScrub: Bool { hasFinishedListening }

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

  public enum AsyncAction: Equatable {
    case startTicking
    case stopTicking
  }

  public enum InnerAction: Equatable {
    case tick
  }

  public enum DelegateAction: Equatable {
    case dismiss
  }

  nonisolated enum CancelID: Hashable {
    case tick
  }

  @Dependency(\.continuousClock) var clock

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
      return .send(.async(.stopTicking)).concatenate(with: .send(.delegate(.dismiss)))
    case .refreshTapped:
      state.currentTime = 0
      state.isPlaying = false
      return .send(.async(.stopTicking))
    case .togglePlayTapped:
      state.isPlaying.toggle()
      return state.isPlaying ? .send(.async(.startTicking)) : .send(.async(.stopTicking))
    case .seekBackwardTapped:
      guard state.canScrub else { return .none }
      state.currentTime = max(0, state.currentTime - 15)
      return .none
    case .seekForwardTapped:
      guard state.canScrub else { return .none }
      state.currentTime = min(state.totalDuration, state.currentTime + 15)
      return .none
    case let .scrub(time):
      guard state.canScrub else { return .none }
      state.currentTime = min(max(0, time), state.totalDuration)
      return .none
    }
  }

  private func handleAsyncAction(state _: inout State, action: AsyncAction) -> Effect<Action> {
    switch action {
    case .startTicking:
      .run { [clock] send in
        for await _ in clock.timer(interval: .seconds(1)) {
          await send(.inner(.tick))
        }
      }
      .cancellable(id: CancelID.tick, cancelInFlight: true)

    case .stopTicking:
      .cancel(id: CancelID.tick)
    }
  }

  private func handleInnerAction(state: inout State, action: InnerAction) -> Effect<Action> {
    switch action {
    case .tick:
      let next = state.currentTime + 1
      if next >= state.totalDuration {
        state.currentTime = state.totalDuration
        state.isPlaying = false
        state.hasFinishedListening = true
        return .send(.async(.stopTicking))
      }
      state.currentTime = next
      return .none
    }
  }

  private func handleDelegateAction(state _: inout State, action: DelegateAction) -> Effect<Action> {
    switch action {
    case .dismiss:
      .none
    }
  }
}
