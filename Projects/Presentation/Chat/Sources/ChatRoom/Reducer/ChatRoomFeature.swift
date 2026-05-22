//
//  ChatRoomFeature.swift
//  Home
//
//  Created by Wonji Suh on 5/19/26.
//

import Foundation

import ComposableArchitecture
import DesignSystem
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
    /// 한 번 끝까지 재생된 콘텐츠는 이후 재진입 시 시킹/건너뛰기를 허용한다.
    public var hasFinishedListening: Bool = false
    public var hasPresentedFinalVoteAlert: Bool = false
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?

    /// 현재 재생 중인 시나리오 노드 id (없으면 startNodeId 폴백)
    public var currentNodeId: Int?
    /// 현재 타임라인에서 화면에 노출된 노드들. nextNodeId/autoNextNodeId 를 따라 누적된다.
    public var visibleNodeIds: [Int] = []
    /// 인터랙티브 노드 끝에 도달해 사용자의 입장 선택을 기다리는 상태.
    public var isWaitingForNodeSelection: Bool = false
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
      let nodes = visibleNodes(in: scenario)
      return nodes.flatMap { node in
        node.scripts.map { script in
          ChatMessage(
            messageId: Self.scriptUUID(scriptId: script.scriptId),
            speaker: speaker(for: script, in: scenario),
            text: script.text,
            startTimeMs: script.startTimeMs
          )
        }
      }
    }

    /// 같은 scriptId 면 동일한 UUID 를 반환해 ForEach 의 id 가 매 렌더링마다
    /// 흔들리지 않도록 한다 (자동 스크롤 target 안정화).
    private static func scriptUUID(scriptId: Int) -> UUID {
      let hex = String(format: "%012X", scriptId)
      return UUID(uuidString: "00000000-0000-0000-0000-\(hex)") ?? UUID()
    }

    /// 현재 재생 시점에 해당하는 메시지 id. `currentTime` 이상의 startTimeMs 를
    /// 가지지 않은 마지막 메시지를 활성으로 본다.
    public var activeMessageId: UUID? {
      let currentMs = Int(currentTime * 1000)
      var active: ChatMessage?
      for message in messages {
        guard let start = message.startTimeMs else { continue }
        if start <= currentMs { active = message } else { break }
      }
      return active?.id ?? messages.first?.id
    }

    public var audioUrl: String? {
      guard let scenario else { return nil }
      if let url = scenario.audios[scenario.recommendedPathKey.rawValue] { return url }
      return scenario.audios.values.first
    }

    public var canScrub: Bool { hasFinishedListening }

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
      guard isWaitingForNodeSelection else { return [] }
      return currentNode?.interactiveOptions ?? []
    }

    public var visibleOptions: [ScenarioInteractiveOption] {
      interactiveOptions
    }

    public var shouldShowOptions: Bool {
      isWaitingForNodeSelection && !visibleOptions.isEmpty
    }

    public var isConfirmEnabled: Bool { selectedOptionLabel != nil }

    public init(battleId: Int = 0) {
      self.battleId = battleId
      hasFinishedListening = Self.hasListenedBefore(battleId: battleId)
    }

    private static func hasListenedBefore(battleId: Int) -> Bool {
      UserDefaults.standard.bool(forKey: listenedKey(battleId: battleId))
    }

    fileprivate static func listenedKey(battleId: Int) -> String {
      "picke.chatRoom.hasFinishedListening.\(battleId)"
    }

    public func visibleNodes(in scenario: BattleScenario) -> [ScenarioNode] {
      let ids = visibleNodeIds.isEmpty ? [currentNodeId ?? scenario.startNodeId] : visibleNodeIds
      return ids.compactMap { id in
        scenario.nodes.first { $0.nodeId == id }
      }
    }

    public func nodeStartTime(for nodeId: Int) -> TimeInterval {
      guard let node = scenario?.nodes.first(where: { $0.nodeId == nodeId }) else { return 0 }
      return TimeInterval((node.scripts.map(\.startTimeMs).min() ?? 0)) / 1000
    }

    public func nodeEndTime(for node: ScenarioNode) -> TimeInterval {
      let start = TimeInterval((node.scripts.map(\.startTimeMs).min() ?? 0)) / 1000
      return start + TimeInterval(node.audioDuration)
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case scope(ScopeAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case onAppear
    case onDisappear
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
    case scenarioResponse(Result<BattleScenario, BattleError>)
    case playerTimeUpdated(TimeInterval)
    case playerDurationUpdated(TimeInterval)
  }

  @CasePathable
  public enum ScopeAction: Equatable {
    case customAlert(PresentationAction<CustomAlertAction>)
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case requestFinalVote(battleId: Int)
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
      case let .scope(scopeAction):
        handleScopeAction(state: &state, action: scopeAction)
      case let .delegate(delegateAction):
        handleDelegateAction(state: &state, action: delegateAction)
      }
    }
    .ifLet(\.$customAlert, action: \.scope.customAlert) {
      CustomConfirmAlert()
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

    case .onDisappear:
      state.isPlaying = false
      return .merge(
        .cancel(id: CancelID.audioObserver),
        .run { [player = audioPlayer] _ in await player.pause() }
      )

    case .backButtonTapped:
      return .run { [player = audioPlayer] send in
        await player.pause()
        await send(.delegate(.dismiss))
      }

    case .refreshTapped:
      state.currentTime = 0
      state.isPlaying = false
      state.currentNodeId = state.scenario?.startNodeId
      state.visibleNodeIds = state.scenario.map { [$0.startNodeId] } ?? []
      state.isWaitingForNodeSelection = false
      state.selectedOptionLabel = nil
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
            let option = state.visibleOptions.first(where: { $0.label == label })
      else { return .none }
      state.currentNodeId = option.nextNodeId
      if !state.visibleNodeIds.contains(option.nextNodeId) {
        state.visibleNodeIds.append(option.nextNodeId)
      }
      state.selectedOptionLabel = nil
      state.isWaitingForNodeSelection = false
      let targetTime = state.nodeStartTime(for: option.nextNodeId)
      state.currentTime = targetTime
      state.isPlaying = true
      return .run { [player = audioPlayer] _ in
        await player.seek(to: targetTime)
        await player.play()
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
        .mapError(BattleError.from)
        return await send(.inner(.scenarioResponse(result)))
      }
      .cancellable(id: CancelID.fetchScenario, cancelInFlight: true)

    case let .loadAudio(url):
      state.currentTime = 0
      state.playerDuration = 0
      state.isPlaying = true
      return .run { [player = audioPlayer] send in
        await player.load(url: url)
        let duration = await player.duration()
        if duration > 0 {
          await send(.inner(.playerDurationUpdated(duration)))
        }
        await player.play()
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
        if state.visibleNodeIds.isEmpty {
          state.visibleNodeIds = [scenario.startNodeId]
        }
        state.isWaitingForNodeSelection = false
        state.selectedOptionLabel = nil
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
      if let effect = advanceNodeIfNeeded(state: &state, time: time) {
        return effect
      }
      if state.totalDuration > 0,
         time >= state.totalDuration - 0.5
      {
        if !state.hasFinishedListening {
          state.hasFinishedListening = true
          UserDefaults.standard.set(true, forKey: State.listenedKey(battleId: state.battleId))
        }
        state.isPlaying = false
        if !state.hasPresentedFinalVoteAlert {
          state.hasPresentedFinalVoteAlert = true
          state.customAlert = .finalVote()
        }
      }
      return .none

    case let .playerDurationUpdated(duration):
      state.playerDuration = duration
      return .none
    }
  }

  private func advanceNodeIfNeeded(
    state: inout State,
    time: TimeInterval
  ) -> Effect<Action>? {
    guard let scenario = state.scenario,
          let currentNode = state.currentNode
    else { return nil }

    let nodeEndTime = state.nodeEndTime(for: currentNode)
    guard time >= nodeEndTime - 0.25 else { return nil }

    if !currentNode.interactiveOptions.isEmpty {
      guard !state.isWaitingForNodeSelection else { return nil }
      state.isWaitingForNodeSelection = true
      state.isPlaying = false
      return .run { [player = audioPlayer] _ in
        await player.pause()
      }
    }

    guard let nextNodeId = currentNode.autoNextNodeId,
          scenario.nodes.contains(where: { $0.nodeId == nextNodeId }),
          state.currentNodeId != nextNodeId
    else { return nil }

    state.currentNodeId = nextNodeId
    if !state.visibleNodeIds.contains(nextNodeId) {
      state.visibleNodeIds.append(nextNodeId)
    }
    return .none
  }

  private func handleScopeAction(state: inout State, action: ScopeAction) -> Effect<Action> {
    switch action {
    case let .customAlert(alertAction):
      switch alertAction {
      case let .presented(customAlertAction):
        switch customAlertAction {
        case .confirmTapped:
          state.customAlert = nil
          let battleId = state.battleId
          return .run { [player = audioPlayer] send in
            await player.pause()
            await send(.delegate(.requestFinalVote(battleId: battleId)))
          }
        case .cancelTapped:
          state.customAlert = nil
          state.currentTime = 0
          state.isPlaying = true
          return .run { [player = audioPlayer] _ in
            await player.seek(to: 0)
            await player.play()
          }
        }
      case .dismiss:
        state.customAlert = nil
        return .none
      }
    }
  }

  private func handleDelegateAction(state _: inout State, action: DelegateAction) -> Effect<Action> {
    switch action {
    case .dismiss, .requestFinalVote:
      .none
    }
  }
}
