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
    public var playerDuration: TimeInterval = 0
    public var battleId: Int = 0
    public var isLoadingScenario: Bool = false
    /// 한 번 끝까지 재생되어야 시킹(드래그) 허용
    public var hasFinishedListening: Bool = false

    /// 현재 재생 중인 시나리오 노드 id (없으면 startNodeId 폴백)
    public var currentNodeId: Int?
    /// 선택지 영역에서 사용자가 탭한 옵션 label
    public var selectedOptionLabel: String?

    public var totalDuration: TimeInterval {
      if playerDuration > 0 { return playerDuration }
      guard let scenario else { return bundle.totalDuration }
      let nodesTotal = scenario.nodes.reduce(0) { $0 + $1.audioDuration }
      return nodesTotal > 0 ? TimeInterval(nodesTotal) : bundle.totalDuration
    }

    public var battleTitle: String { scenario?.title ?? bundle.battleTitle }

    public var messages: [ChatMessage] {
      guard let scenario else { return bundle.messages }
      return scenario.nodes.flatMap { node in
        node.scripts.map { script in
          return ChatMessage(
            speaker: speaker(for: script, in: scenario),
            text: script.text
          )
        }
      }
    }

    public var audioUrl: String? {
      guard let scenario else { return nil }
      if let url = scenario.audios[scenario.recommendedPathKey.rawValue] { return url }
      return scenario.audios.values.first
    }

    public var canScrub: Bool { true }

    private func speaker(for script: ScenarioScript, in scenario: BattleScenario) -> ChatSpeaker {
      switch script.speakerType {
      case .a:
        return speaker(label: "A", side: .left, fallbackName: script.speakerName, in: scenario)
      case .b:
        return speaker(label: "B", side: .right, fallbackName: script.speakerName, in: scenario)
      case .narrator:
        return ChatSpeaker(name: script.speakerName, side: .center)
      case .philosopher, .unknown:
        if let philosopher = scenario.philosophers.first(where: { $0.name == script.speakerName }) {
          let side: ChatSpeakerSide = philosopher.label == "B" ? .right : .left
          return ChatSpeaker(
            label: philosopher.label,
            name: philosopher.name,
            imageURL: philosopher.imageUrl,
            side: side
          )
        }
        return ChatSpeaker(name: script.speakerName, side: .center)
      }
    }

    private func speaker(
      label: String,
      side: ChatSpeakerSide,
      fallbackName: String,
      in scenario: BattleScenario
    ) -> ChatSpeaker {
      guard let philosopher = scenario.philosophers.first(where: { $0.label == label }) else {
        return ChatSpeaker(label: label, name: fallbackName, side: side)
      }
      return ChatSpeaker(
        label: philosopher.label,
        name: philosopher.name,
        imageURL: philosopher.imageUrl,
        side: side
      )
    }

    public var currentNode: ScenarioNode? {
      guard let scenario else { return nil }
      let target = currentNodeId ?? scenario.startNodeId
      return scenario.nodes.first { $0.nodeId == target }
    }

    public var interactiveOptions: [ScenarioInteractiveOption] {
      currentNode?.interactiveOptions ?? []
    }

    /// 현재 노드에 선택지가 있으면 선택 카드 노출 (실재생 연동 전 임시 — 항상 노출)
    public var shouldShowOptions: Bool {
      !interactiveOptions.isEmpty
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
    case fetchScenario
    case loadAudio(URL)
    case subscribePlayer
  }

  public enum InnerAction: Equatable {
    case scenarioResponse(Result<BattleScenario, AuthError>)
    case playerTimeUpdated(TimeInterval)
    case playerDurationUpdated(TimeInterval)
  }

  public enum DelegateAction: Equatable {
    case dismiss
  }

  nonisolated enum CancelID: Hashable {
    case fetchScenario
    case audioObserver
  }

  @Dependency(\.battleRepository) private var battleRepository
  @Dependency(\.audioPlayer) private var audioPlayer

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
      let needsFetch = state.scenario == nil && !state.isLoadingScenario
      let subscribe: Effect<Action> = .send(.async(.subscribePlayer))
      return needsFetch
        ? subscribe.merge(with: .send(.async(.fetchScenario)))
        : subscribe

    case .backButtonTapped:
      return .run { [player = audioPlayer] send in
        await player.pause()
        await send(.delegate(.dismiss))
      }

    case .refreshTapped:
      state.currentTime = 0
      state.isPlaying = false
      return .run { [player = audioPlayer] _ in
        await player.pause()
        await player.seek(to: 0)
      }

    case .togglePlayTapped:
      state.isPlaying.toggle()
      let playing = state.isPlaying
      return .run { [player = audioPlayer] _ in
        if playing { await player.play() } else { await player.pause() }
      }

    case .seekBackwardTapped:
      guard state.canScrub else { return .none }
      let target = max(0, state.currentTime - 15)
      state.currentTime = target
      return .run { [player = audioPlayer] _ in
        await player.seek(to: target)
      }

    case .seekForwardTapped:
      guard state.canScrub else { return .none }
      let target = min(state.totalDuration, state.currentTime + 15)
      state.currentTime = target
      return .run { [player = audioPlayer] _ in
        await player.seek(to: target)
      }

    case let .scrub(time):
      guard state.canScrub else { return .none }
      let target = min(max(0, time), state.totalDuration)
      state.currentTime = target
      return .run { [player = audioPlayer] _ in
        await player.seek(to: target)
      }

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
      return .run { [player = audioPlayer] _ in
        await player.pause()
        await player.seek(to: 0)
      }
    }
  }

  private func handleAsyncAction(state: inout State, action: AsyncAction) -> Effect<Action> {
    switch action {
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

    case let .loadAudio(url):
      state.currentTime = 0
      state.playerDuration = 0
      return .run { [player = audioPlayer] send in
        await player.load(url: url)
        let duration = await player.duration()
        if duration > 0 {
          await send(.inner(.playerDurationUpdated(duration)))
        }
      }

    case .subscribePlayer:
      return .run { [player = audioPlayer] send in
        for await time in player.currentTimes() {
          await send(.inner(.playerTimeUpdated(time)))
        }
      }
      .cancellable(id: CancelID.audioObserver, cancelInFlight: true)
    }
  }

  private func handleInnerAction(state: inout State, action: InnerAction) -> Effect<Action> {
    switch action {
    case let .scenarioResponse(result):
      state.isLoadingScenario = false
      switch result {
      case let .success(scenario):
        state.scenario = scenario
        if state.currentNodeId == nil {
          state.currentNodeId = scenario.startNodeId
        }
        if let urlString = scenario.audios[scenario.recommendedPathKey.rawValue]
          ?? scenario.audios.values.first,
          let url = URL(string: urlString)
        {
          return .send(.async(.loadAudio(url)))
        }
        return .none
      case let .failure(error):
        Log.error("[ChatRoomFeature] fetchScenario failed: \(error.localizedDescription)")
        return .none
      }

    case let .playerTimeUpdated(time):
      state.currentTime = time
      if state.totalDuration > 0, time >= state.totalDuration - 0.5 {
        state.hasFinishedListening = true
        state.isPlaying = false
      }
      return .none

    case let .playerDurationUpdated(duration):
      state.playerDuration = duration
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
