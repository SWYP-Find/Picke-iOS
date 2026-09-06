//
//  ChatRoomFeature.swift
//  Home
//
//  Created by Wonji Suh on 5/19/26.
//

import Foundation

import BattleDomainInterface
import ChatInterface
import ComposableArchitecture
import HomeDomainInterface
import LogMacro
import PickeDesignKit
import PickeFoundation
import AnalyticsServiceInterface
import AudioPlayerServiceInterface

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
    /// 오디오 로딩 실패 시 상단 floating 오류 배너 노출 여부.
    public var hasAudioError: Bool = false
    /// 시나리오 로드(디코딩/네트워크) 실패 여부. true 면 목업 대신 오류+재시도 UI 를 노출한다.
    public var scenarioLoadFailed: Bool = false
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
    /// 중간(분기) 선택 확정 내역 — 선택 후에도 대화 흐름 중간에 유지 노출한다. (안드로이드 ScenarioScreen 파리티)
    public var confirmedSelection: ConfirmedSelection?

    public struct ConfirmedSelection: Equatable {
      public let options: [ScenarioInteractiveOption]
      public let selectedNodeId: Int
    }

    /// 수동 seek(분기 선택·구간 이동) 직후 목표 시간. iOS 는 seek 반영 전 stale tick 을
    /// 흘리므로, 목표 시간 근처에 도달하기 전까지 옵저버 tick 을 무시해 오디오-텍스트 불일치를 막는다.
    public var pendingSeekTime: TimeInterval?

    public var totalDuration: TimeInterval {
      if playerDuration > 0 { return playerDuration }
      guard let scenario else { return bundle.totalDuration }
      let nodesTotal = scenario.nodes.reduce(0) { $0 + $1.audioDuration }
      return nodesTotal > 0 ? TimeInterval(nodesTotal) : bundle.totalDuration
    }

    public var battleTitle: String { scenario?.title ?? bundle.battleTitle }

    public var messages: [ChatMessage] {
      // scenario 가 nil(미로드/로드 실패)이면 목업을 노출하지 않는다.
      // 과거엔 bundle.messages(목업 전체)를 반환해 "재생 안 됨 + 전체 내용 노출" 버그가 있었다.
      guard let scenario else { return [] }
      let nodes = visibleNodes(in: scenario)
      let currentMs = Int(currentTime * 1000)
      return nodes.flatMap { node -> [ChatMessage] in
        let scripts = node.scripts
        // 대사별 startTimeMs 가 구분되면 그 값을, 모두 같거나(0) 평평하면 노드 오디오 구간에 균등 분배.
        let distinctStarts = Set(scripts.map(\.startTimeMs)).count
        let nodeStartMs = scripts.map(\.startTimeMs).min() ?? 0
        let nodeDurationMs = node.audioDuration * 1000
        let count = scripts.count

        func revealStart(_ index: Int) -> Int {
          if distinctStarts > 1 { return scripts[index].startTimeMs }
          if count > 1 { return nodeStartMs + nodeDurationMs * index / count }
          return nodeStartMs
        }

        return scripts.enumerated().flatMap { index, script -> [ChatMessage] in
          let scriptStart = revealStart(index)
          guard currentMs >= scriptStart else { return [] }
          let scriptEnd = index + 1 < count ? revealStart(index + 1) : nodeStartMs + nodeDurationMs
          let windowMs = max(1, scriptEnd - scriptStart)
          let messageSpeaker = speaker(for: script, in: scenario)

          // 나레이션/클로징(center)·발언자(좌/우) 모두 문장마다 개별 말풍선.
          // 문장 시작 시점은 글자수 비례로 분배(긴 문장=더 긴 시간) → 싱크.
          let sentences = script.text.splitIntoSentences()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
          guard sentences.count > 1 else {
            return [ChatMessage(
              messageId: UUID.deterministic(script.scriptId, 0),
              speaker: messageSpeaker,
              text: script.text,
              startTimeMs: scriptStart
            )]
          }
          let totalChars = max(1, sentences.reduce(0) { $0 + $1.count })
          var charsBefore = 0
          var result: [ChatMessage] = []
          for (sentenceIndex, sentence) in sentences.enumerated() {
            let sentenceStart = scriptStart + windowMs * charsBefore / totalChars
            charsBefore += sentence.count
            guard currentMs >= sentenceStart else { break }
            result.append(ChatMessage(
              messageId: UUID.deterministic(script.scriptId, sentenceIndex),
              speaker: messageSpeaker,
              text: sentence,
              startTimeMs: sentenceStart
            ))
          }
          return result
        }
      }
    }

    /// 현재 재생 중(가장 최근 노출된) 메시지 id. 문장 단위 노출이라 마지막 노출 버블이 활성.
    public var activeMessageId: UUID? {
      messages.last?.id
    }

    public var audioUrl: String? {
      guard let scenario else { return nil }
      if let url = scenario.audios[scenario.recommendedPathKey.rawValue] { return url }
      return scenario.audios.values.first
    }

    public var canScrub: Bool { hasFinishedListening }

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

    /// 확정 선택 내역 블록을 끼워 넣을 기준 시각(ms) — 선택된 노드의 시작. 내역 없으면 nil.
    public var confirmedSelectionStartMs: Int? {
      guard let confirmedSelection else { return nil }
      return Int(nodeStartTime(for: confirmedSelection.selectedNodeId) * 1000)
    }

    public var isConfirmEnabled: Bool { selectedOptionLabel != nil }

    public init(battleId: Int = 0) {
      self.battleId = battleId
      hasFinishedListening = Self.hasListenedBefore(battleId: battleId)
    }

    public init(route: ChatRoomRoute) {
      self.init(battleId: route.battleId)
    }

    private static func hasListenedBefore(battleId: Int) -> Bool {
      UserDefaults.standard.bool(forKey: listenedKey(battleId: battleId))
    }

    fileprivate static func listenedKey(battleId: Int) -> String {
      "picke.chatRoom.hasFinishedListening.\(battleId)"
    }

    public func nodeStartTime(for nodeId: Int) -> TimeInterval {
      scenario?.nodeStartTime(for: nodeId) ?? 0
    }

    public func nodeEndTime(for node: ScenarioNode) -> TimeInterval {
      scenario?.nodeEndTime(for: node) ?? 0
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case scope(ScopeAction)
    case delegate(ChatRoomDelegate)
  }

  @CasePathable
  public enum View {
    case onAppear
    case onDisappear
    case backButtonTapped
    case refreshTapped
    case retryTapped
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
    case audioLoadFailed
    case dismissAudioError
  }

  @CasePathable
  public enum ScopeAction: Equatable {
    case customAlert(PresentationAction<CustomAlertAction>)
  }

  nonisolated enum CancelID: Hashable {
    case fetchScenario
    case audioObserver
    case audioErrorDismiss
  }

  @Dependency(\.battleUseCase) private var battleUseCase
  @Dependency(\.audioPlayer) private var audioPlayer
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

private extension ChatRoomFeature.State {
  func visibleNodes(in scenario: BattleScenario) -> [ScenarioNode] {
    let ids = visibleNodeIds.isEmpty ? [currentNodeId ?? scenario.startNodeId] : visibleNodeIds
    return ids.compactMap { id in
      scenario.nodes.first { $0.nodeId == id }
    }
  }

  func speaker(
    for script: ScenarioScript,
    in scenario: BattleScenario
  ) -> ChatSpeaker {
    switch script.speakerType {
    case .a:
      return speaker(
        label: "A",
        side: .left,
        fallbackName: script.speakerName,
        in: scenario
      )
    case .b:
      return speaker(
        label: "B",
        side: .right,
        fallbackName: script.speakerName,
        in: scenario
      )
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

  func speaker(
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
}

extension ChatRoomFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      analyticsUseCase.track(.screenView(screen: .chatroom, referrer: nil))
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
      state.confirmedSelection = nil
      // 처음부터 다시 들을 때도 최종투표 팝업이 다시 뜨도록 1회성 플래그를 리셋한다.
      state.hasPresentedFinalVoteAlert = false
      return .run { [player = audioPlayer] _ in
        await player.pause()
        await player.seek(to: 0)
      }

    case .retryTapped:
      return .send(.async(.fetchScenario))

    case .togglePlayTapped:
      analyticsUseCase.track(.uiAction(action: .chatroomPlay, screen: .chatroom))
      state.isPlaying.toggle()
      let playing = state.isPlaying
      return .run { [player = audioPlayer] _ in
        if playing { await player.play() } else { await player.pause() }
      }

    case .seekBackwardTapped:
      analyticsUseCase.track(.uiAction(action: .chatroomSeekBackward, screen: .chatroom))
      // 15초 되감기 버튼은 첫 재생 중에도 항상 동작한다 (canScrub 게이트는 드래그 스크럽 전용).
      let target = max(0, state.currentTime - 15)
      state.currentTime = target
      state.pendingSeekTime = target
      return .run { [player = audioPlayer] _ in
        await player.seek(to: target)
      }

    case .seekForwardTapped:
      analyticsUseCase.track(.uiAction(action: .chatroomSeekForward, screen: .chatroom))
      // 15초 넘기기 버튼은 첫 재생 중에도 항상 동작한다 (canScrub 게이트는 드래그 스크럽 전용).
      let target = min(state.totalDuration, state.currentTime + 15)
      state.currentTime = target
      state.pendingSeekTime = target
      return .run { [player = audioPlayer] _ in
        await player.seek(to: target)
      }

    case let .scrub(time):
      guard state.canScrub else { return .none }
      let target = min(max(0, time), state.totalDuration)
      state.currentTime = target
      state.pendingSeekTime = target
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
      // 선택 내역을 대화 흐름 중간에 계속 노출하기 위해 확정 시점의 선택지를 보존.
      state.confirmedSelection = .init(
        options: state.visibleOptions,
        selectedNodeId: option.nextNodeId
      )
      state.selectedOptionLabel = nil
      state.isWaitingForNodeSelection = false
      let targetTime = state.nodeStartTime(for: option.nextNodeId)
      state.currentTime = targetTime
      state.pendingSeekTime = targetTime
      state.isPlaying = true
      return .run { [player = audioPlayer] _ in
        await player.seek(to: targetTime)
        await player.play()
      }
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetchScenario:
      state.isLoadingScenario = true
      state.scenarioLoadFailed = false
      let battleId = state.battleId
      return .run { [repository = battleUseCase] send in
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
      state.hasAudioError = false
      return .run { [player = audioPlayer] send in
        let isPlayable = await player.load(url: url)
        guard isPlayable else {
          await send(.inner(.audioLoadFailed))
          return
        }
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

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .scenarioResponse(result):
      state.isLoadingScenario = false
      switch result {
      case let .success(scenario):
        state.scenario = scenario
        state.scenarioLoadFailed = false
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
        state.scenarioLoadFailed = true
        Log.error("[ChatRoomFeature] fetchScenario failed: \(error) — \(error.localizedDescription)")
        return .none
      }

    case let .playerTimeUpdated(time):
      // 수동 seek(분기 선택·구간 이동) 직후, iOS 는 seek 반영 전 stale tick 을 흘린다.
      // 목표 시간 근처에 도달하기 전까지 tick 을 무시해 노드가 어긋나지 않게 한다(오디오-텍스트 동기).
      if let pending = state.pendingSeekTime {
        guard abs(time - pending) < 0.5 else { return .none }
        state.pendingSeekTime = nil
      }
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
          analyticsUseCase.track(
            .battleStep(BattleStepData(stepName: .audioEnd, contentID: "\(state.battleId)"))
          )
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

    case .audioLoadFailed:
      state.isPlaying = false
      state.hasAudioError = true
      // 3초 후 자동으로 배너 숨김.
      return .run { send in
        try? await Task.sleep(for: .seconds(3))
        await send(.inner(.dismissAudioError))
      }
      .cancellable(id: CancelID.audioErrorDismiss, cancelInFlight: true)

    case .dismissAudioError:
      state.hasAudioError = false
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
    guard time >= nodeEndTime else { return nil }

    if !currentNode.interactiveOptions.isEmpty {
      guard !state.isWaitingForNodeSelection else { return nil }
      state.isWaitingForNodeSelection = true
      state.isPlaying = false
      // 선택지 노출 시점에 이 노드의 대사가 전부 드러나도록 currentTime 을 노드 끝으로 고정
      // (음성이 끝나기 전 일찍 멈춰 글이 튀어 보이던 문제 방지).
      state.currentTime = max(state.currentTime, nodeEndTime)
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

  private func handleScopeAction(
    state: inout State,
    action: ScopeAction
  ) -> Effect<Action> {
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
          // 다시 듣기(replay) 후 끝까지 들으면 최종투표 팝업이 재노출되도록 1회성 플래그를 리셋한다.
          state.hasPresentedFinalVoteAlert = false
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

  private func handleDelegateAction(
    state _: inout State,
    action: ChatRoomDelegate
  ) -> Effect<Action> {
    switch action {
    case .dismiss, .requestFinalVote:
      .none
    }
  }
}
