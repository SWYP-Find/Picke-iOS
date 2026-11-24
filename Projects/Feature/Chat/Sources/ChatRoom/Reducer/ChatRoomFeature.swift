//
//  ChatRoomFeature.swift
//  Chat
//
//  Created by Picke on 5/19/26.
//

import AudioPlayerServiceInterface
import BattleDomainInterface
import ChatInterface
import ComposableArchitecture
import Foundation
import HomeDomainInterface
import PickeAnalyticsInterface
import PickeCoreLogger
import PickeCoreUtility
import PickeDesignKit
import PickeSharedUI

@Reducer
public struct ChatRoomFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public let instanceID = UUID()
    public var scenario: BattleScenario?
    public var isPlaying: Bool = false
    public var playbackRate: Float = 1
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
    /// Android `isReviewing` — "다시 들어볼래요" 뒤에는 대사를 모두 보이고 리스트 끝에 "최종투표 하러가기" 를 둔다.
    public var isReviewing: Bool = false
    /// Android `maxListenedPositionMs` — 슬라이더·말풍선 탭은 지금까지 들은 위치까지만 이동한다.
    public var maxListenedTime: TimeInterval = 0
    /// Android `ScenarioUiEvent` 토스트 문구. 보여준 뒤 `toastShown` 으로 비운다.
    public var toastMessage: String?
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

    /// Android `AudioPlayerDefaults.PLAYBACK_SPEEDS` — 탭할 때마다 이 순서로 돈다.
    public static let supportedPlaybackRates: [Float] = [1, 1.5, 2, 3]

    public var playbackRateTitle: String {
      String(format: "%.1f", playbackRate)
    }

    public var nextPlaybackRate: Float {
      let rates = Self.supportedPlaybackRates
      let index = rates.firstIndex(of: playbackRate) ?? 0
      return rates[(index + 1) % rates.count]
    }

    public var totalDuration: TimeInterval {
      if playerDuration > 0 {
        return playerDuration
      }
      // Android 는 불러오기 전 제목·시간을 비워 둔다(0:00). 목업 값을 보이지 않는다.
      guard let scenario else { return 0 }
      let nodesTotal = scenario.nodes.reduce(0) { $0 + $1.audioDuration }
      return TimeInterval(nodesTotal)
    }

    public var battleTitle: String {
      scenario?.title ?? ""
    }

    public var messages: [ChatMessage] {
      // scenario 가 nil(미로드/로드 실패)이면 빈 목록이다.
      guard let scenario else { return [] }
      return ChatRoomTimelineUseCase().messages(
        scenario: scenario,
        visibleNodeIds: visibleNodeIds,
        currentNodeId: currentNodeId,
        currentTime: isReviewing ? max(currentTime, totalDuration) : currentTime
      )
    }

    /// 지금 재생 위치의 대사. 다시 듣는 중에는 전체가 보이므로 시작 시각으로 고른다(Android `indexOfLast`).
    public var activeMessageId: UUID? {
      let currentMs = Int(currentTime * 1000)
      return messages.last { ($0.startTimeMs ?? 0) <= currentMs }?.id
    }

    public var audioUrl: String? {
      guard let scenario else { return nil }
      if let url = scenario.audios[scenario.recommendedPathKey.rawValue] {
        return url
      }
      return scenario.audios.values.first
    }

    /// Android `isForwardEnabled` — 선택지·최종투표 대화상자·오디오 오류 중에는 15초 넘기기를 막는다.
    public var isForwardEnabled: Bool {
      !shouldShowOptions && customAlert == nil && !hasAudioError
    }

    /// 현재 노드 구간. Android 는 노드마다 오디오가 따로라 이동이 노드 안에서만 일어난다.
    public var currentNodeRange: ClosedRange<TimeInterval> {
      guard let currentNode else { return 0 ... max(totalDuration, 0) }
      let start = nodeStartTime(for: currentNode.nodeId)
      return start ... max(start, nodeEndTime(for: currentNode))
    }

    /// Android `seekToPosition` — 노드 끝과 들은 위치 중 앞쪽까지만 이동한다.
    public func clampedSeekTime(_ time: TimeInterval) -> TimeInterval {
      let range = currentNodeRange
      let upper = max(range.lowerBound, min(range.upperBound, maxListenedTime))
      return min(max(time, range.lowerBound), upper)
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

    /// 확정 선택 내역 블록을 끼워 넣을 기준 시각(ms) — 선택된 노드의 시작. 내역 없으면 nil.
    public var confirmedSelectionStartMs: Int? {
      guard let confirmedSelection else { return nil }
      return Int(nodeStartTime(for: confirmedSelection.selectedNodeId) * 1000)
    }

    public var isConfirmEnabled: Bool {
      selectedOptionLabel != nil
    }

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
    case toastShown
    case togglePlayTapped
    case playbackRateSelected(Float)
    case seekBackwardTapped
    case seekForwardTapped
    case replayTapped
    case scrub(TimeInterval)
    case messageTapped(UUID)
    case goToFinalVoteTapped
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

  public nonisolated enum CancelID: Hashable, Sendable {
    case fetchScenario
    case audioObserver(UUID)
    case sharedAudioObserver
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
        .cancel(id: CancelID.audioObserver(state.instanceID)),
        .run { [player = audioPlayer] _ in await player.pause() }
      )

    case .backButtonTapped:
      return .concatenate(
        .cancel(id: CancelID.audioObserver(state.instanceID)),
        .run { [player = audioPlayer] send in
          await player.pause()
          await send(.delegate(.dismiss))
        }
      )

    case .toastShown:
      state.toastMessage = nil
      return .none

    case .togglePlayTapped:
      analyticsUseCase.track(.uiAction(action: .chatroomPlay, screen: .chatroom))
      state.isPlaying.toggle()
      let playing = state.isPlaying
      return .run { [player = audioPlayer] _ in
        if playing {
          await player.play()
        } else {
          await player.pause()
        }
      }

    case let .playbackRateSelected(rate):
      guard rate.isFinite, State.supportedPlaybackRates.contains(rate) else { return .none }
      state.playbackRate = rate
      return .run { [player = audioPlayer] _ in
        await player.setPlaybackRate(rate)
      }

    case .seekBackwardTapped:
      analyticsUseCase.track(.uiAction(action: .chatroomSeekBackward, screen: .chatroom))
      // Android `seekRewind` — 현재 노드 시작 아래로는 가지 않는다.
      let target = max(state.currentNodeRange.lowerBound, state.currentTime - 15)
      state.currentTime = target
      state.pendingSeekTime = target
      return .run { [player = audioPlayer] _ in
        await player.seek(to: target)
      }

    case .seekForwardTapped:
      // Android `seekForward` — 막힌 상태면 무시하고, 노드 끝까지만 넘긴다.
      guard state.isForwardEnabled else { return .none }
      analyticsUseCase.track(.uiAction(action: .chatroomSeekForward, screen: .chatroom))
      let target = min(state.currentNodeRange.upperBound, state.currentTime + 15)
      state.currentTime = target
      state.pendingSeekTime = target
      return .run { [player = audioPlayer] _ in
        await player.seek(to: target)
      }

    case .replayTapped:
      // Android `replayFromStart` — 항상 동작하며 현재 노드 처음부터 다시 재생한다.
      return seekAndPlay(
        state: &state,
        to: state.currentNodeRange.lowerBound
      )

    case let .messageTapped(id):
      // Android 말풍선 탭 — 현재 노드 대사만 그 시작 위치로 이동해 재생한다.
      guard let message = state.messages.first(where: { $0.id == id }),
            let startMs = message.startTimeMs
      else { return .none }
      let start = TimeInterval(startMs) / 1000
      guard state.currentNodeRange.contains(start) else { return .none }
      return seekAndPlay(
        state: &state,
        to: state.clampedSeekTime(start)
      )

    case .goToFinalVoteTapped:
      return requestFinalVote(state: &state)

    case let .scrub(time):
      let target = state.clampedSeekTime(time)
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
      return .run { [player = audioPlayer, rate = state.playbackRate] send in
        await player.setPlaybackRate(rate)
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
      return .run { [player = audioPlayer, rate = state.playbackRate] send in
        await player.setPlaybackRate(rate)
        for await time in player.currentTimes() {
          guard !Task.isCancelled else { return }
          await send(.inner(.playerTimeUpdated(time)))
        }
      }
      .cancellable(id: CancelID.audioObserver(state.instanceID), cancelInFlight: true)
      .cancellable(id: CancelID.sharedAudioObserver, cancelInFlight: true)
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
        // Android `ShowLoadFailedToast` — 토스트만 띄우고 빈 목록을 유지한다(다시 시도 없음).
        state.scenarioLoadFailed = true
        state.toastMessage = "정보를 불러오지 못했어요"
        PickeLogger.error(
          "[ChatRoomFeature] fetchScenario failed: \(error) — \(error.localizedDescription)",
          category: .ui
        )
        return .none
      }

    case let .playerTimeUpdated(time):
      // 수동 seek(분기 선택·구간 이동) 직후, iOS 는 seek 반영 전 stale tick 을 흘린다.
      // 목표 시간 근처에 도달하기 전까지 tick 을 무시해 노드가 어긋나지 않게 한다(오디오-텍스트 동기).
      if let pending = state.pendingSeekTime {
        guard abs(time - pending) < 0.5 * max(1, Double(state.playbackRate)) else { return .none }
        state.pendingSeekTime = nil
      }
      state.currentTime = time
      state.maxListenedTime = max(state.maxListenedTime, time)
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
        // Android `handleNodeEnd` — 다시 듣는 중에는 대화상자를 다시 띄우지 않는다.
        if !state.isReviewing, !state.hasPresentedFinalVoteAlert {
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

  private func seekAndPlay(
    state: inout State,
    to target: TimeInterval
  ) -> Effect<Action> {
    state.currentTime = target
    state.pendingSeekTime = target
    state.isPlaying = true
    return .run { [player = audioPlayer] _ in
      await player.seek(to: target)
      await player.play()
    }
  }

  private func requestFinalVote(state: inout State) -> Effect<Action> {
    state.isPlaying = false
    let battleId = state.battleId
    return .run { [player = audioPlayer] send in
      await player.pause()
      await send(.delegate(.requestFinalVote(battleId: battleId)))
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

    guard let nextNodeId = scenario.nextNodeId(for: currentNode),
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
          return requestFinalVote(state: &state)
        case .cancelTapped:
          // Android `restartCurrentAudio` — 대사를 모두 보인 채 현재 노드 처음부터 다시 듣는다.
          state.customAlert = nil
          state.isReviewing = true
          return seekAndPlay(
            state: &state,
            to: state.currentNodeRange.lowerBound
          )
        }
      case .dismiss:
        // Android 는 바깥 터치·닫기도 "최종투표하기" 와 같다.
        state.customAlert = nil
        return requestFinalVote(state: &state)
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
