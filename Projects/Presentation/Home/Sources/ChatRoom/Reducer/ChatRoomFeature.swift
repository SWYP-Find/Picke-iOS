//
//  ChatRoomFeature.swift
//  Home
//
//  Created by Wonji Suh on 5/19/26.
//

import Foundation

import ComposableArchitecture
import DomainInterface
import Entity
import LogMacro

@Reducer
public struct ChatRoomFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var bundle: ChatRoomBundle = .mock
    public var scenario: BattleScenario?
    public var isPlaying: Bool = false
    public var currentTime: TimeInterval = 0
    public var battleId: Int = 0
    public var isLoadingScenario: Bool = false
    /// 한 번 끝까지 재생되어야 시킹(드래그) 허용
    public var hasFinishedListening: Bool = false

    /// 현재 재생 중인 시나리오 노드 id (없으면 startNodeId 폴백)
    public var currentNodeId: Int?
    /// 선택지 영역에서 사용자가 탭한 옵션 label
    public var selectedOptionLabel: String?

    public var totalDuration: TimeInterval { bundle.totalDuration }
    public var battleTitle: String { scenario?.title ?? bundle.battleTitle }
    public var messages: [ChatMessage] { bundle.messages }
    public var canScrub: Bool { hasFinishedListening }

    public var currentNode: ScenarioNode? {
      guard let scenario else { return nil }
      let target = currentNodeId ?? scenario.startNodeId
      return scenario.nodes.first { $0.nodeId == target }
    }

    public var interactiveOptions: [ScenarioInteractiveOption] {
      currentNode?.interactiveOptions ?? []
    }

    /// 현재 노드에 선택지가 있고, 한 번 끝까지 들었으면 선택 카드 노출
    public var shouldShowOptions: Bool {
      hasFinishedListening && !interactiveOptions.isEmpty
    }

    public var isConfirmEnabled: Bool { selectedOptionLabel != nil }

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
    case optionTapped(String)
    case confirmOptionTapped
  }

  public enum AsyncAction: Equatable {
    case startTicking
    case stopTicking
    case fetchScenario
  }

  public enum InnerAction: Equatable {
    case tick
    case scenarioResponse(Result<BattleScenario, AuthError>)
  }

  public enum DelegateAction: Equatable {
    case dismiss
  }

  nonisolated enum CancelID: Hashable {
    case tick
    case fetchScenario
  }

  @Dependency(\.continuousClock) var clock
  @Dependency(\.battleRepository) private var battleRepository

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
      guard state.scenario == nil, !state.isLoadingScenario else { return .none }
      return .send(.async(.fetchScenario))
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
    case let .optionTapped(label):
      state.selectedOptionLabel = (state.selectedOptionLabel == label) ? nil : label
      return .none
    case .confirmOptionTapped:
      guard let label = state.selectedOptionLabel,
            let option = state.interactiveOptions.first(where: { $0.label == label })
      else { return .none }
      state.currentNodeId = option.nextNodeId
      state.selectedOptionLabel = nil
      state.currentTime = 0
      state.hasFinishedListening = false
      state.isPlaying = false
      return .send(.async(.stopTicking))
    }
  }

  private func handleAsyncAction(state: inout State, action: AsyncAction) -> Effect<Action> {
    switch action {
    case .startTicking:
      return .run { [clock] send in
        for await _ in clock.timer(interval: .seconds(1)) {
          await send(.inner(.tick))
        }
      }
      .cancellable(id: CancelID.tick, cancelInFlight: true)

    case .stopTicking:
      return .cancel(id: CancelID.tick)

    case .fetchScenario:
      state.isLoadingScenario = true
      let battleId = state.battleId
      return .run { [repository = battleRepository] send in
        let result = await Result {
          try await repository.fetchScenario(battleId: battleId)
        }
        .mapError(AuthError.from)
        return await send(.inner(.scenarioResponse(result)))
      }
      .cancellable(id: CancelID.fetchScenario, cancelInFlight: true)
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

    case let .scenarioResponse(result):
      state.isLoadingScenario = false
      switch result {
      case let .success(scenario):
        state.scenario = scenario
        if state.currentNodeId == nil {
          state.currentNodeId = scenario.startNodeId
        }
      case let .failure(error):
        Log.error("[ChatRoomFeature] fetchScenario failed: \(error.localizedDescription)")
      }
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
