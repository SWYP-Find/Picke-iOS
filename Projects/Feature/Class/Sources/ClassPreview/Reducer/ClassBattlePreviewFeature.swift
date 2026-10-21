//
//  ClassBattlePreviewFeature.swift
//  Class
//
//  Created by Picke on 10/21/26.
//

import AudioPlayerServiceInterface
import BattleDomainInterface
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import HomeDomainInterface
import PickeAnalyticsInterface

@Reducer
public struct ClassBattlePreviewFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public enum ViewState: Equatable {
      case loading
      case loaded
      case error
    }

    public let instanceID: UUID
    public let battle: ClassBattleSummary
    public var viewState: ViewState = .loading
    public var scenario: BattleScenario?
    public var isActive = false
    public var isAudioReady = false
    public var isPlaying = false
    public var hasFinished = false
    public var playbackRate: Float = 1
    public var currentTime: TimeInterval = 0
    public var audioDuration: TimeInterval = 60
    public var pendingSeekTime: TimeInterval?
    public var audioErrorMessage: String?

    public init(battle: ClassBattleSummary) {
      self.battle = battle
      instanceID = UUID()
    }

    public var title: String {
      scenario?.title ?? battle.title
    }

    public var previewDuration: TimeInterval {
      min(60, max(0, audioDuration))
    }

    public var progress: Double {
      guard previewDuration > 0 else { return 0 }
      return min(1, max(0, currentTime / previewDuration))
    }

    public var currentTimeText: String {
      Self.timeText(currentTime)
    }

    public var durationText: String {
      Self.timeText(previewDuration)
    }

    private static func timeText(_ time: TimeInterval) -> String {
      let seconds = Int(max(0, time))
      return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    public var playbackRateTitle: String {
      switch playbackRate {
      case 1: return "1.0"
      case 1.25: return "1.25"
      case 1.5: return "1.5"
      case 2: return "2.0"
      default: return "1.0"
      }
    }

    public var previewScripts: [ScenarioScript] {
      guard let scenario,
            let node = scenario.nodes.first(where: { $0.nodeId == scenario.startNodeId })
      else { return [] }
      return node.scripts.filter { $0.startTimeMs < 60000 }
        .sorted { $0.startTimeMs < $1.startTimeMs }
    }

    public func speaker(for script: ScenarioScript) -> ChatSpeaker {
      let label: String?
      let side: ChatSpeakerSide
      switch script.speakerType {
      case .a:
        label = "A"
        side = .left
      case .b:
        label = "B"
        side = .right
      case .narrator:
        return ChatSpeaker(name: script.speakerName, side: .center)
      case .philosopher, .unknown:
        label = scenario?.philosophers.first(where: { $0.name == script.speakerName })?.label
        side = label == "B" ? .right : .left
      }
      let philosopher = scenario?.philosophers.first { $0.label == label }
      return ChatSpeaker(
        label: label,
        name: philosopher?.name ?? script.speakerName,
        imageURL: philosopher?.imageUrl,
        side: side
      )
    }
  }

  public enum Action: ViewAction {
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case onAppear
    case onDisappear
    case backTapped
    case retryTapped
    case togglePlayTapped
    case playbackRateSelected(Float)
    case seekBackwardTapped
    case seekForwardTapped
    case replayTapped
    case scrubbed(TimeInterval)
  }

  public enum AsyncAction: Equatable {
    case fetchScenario(Int)
    case loadAudio(URL)
    case observeTime(UUID)
  }

  public enum InnerAction: Equatable {
    case scenarioResponse(Result<BattleScenario, BattleError>)
    case audioLoaded(Bool, TimeInterval)
    case playerTimeUpdated(TimeInterval)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
  }

  nonisolated enum CancelID: Hashable {
    case scenario(UUID)
    case audioLoad(UUID)
    case audioObserver(UUID)
  }

  @Dependency(\.classBattlePreviewDependencies) private var previewDependencies

  private var battleUseCase: any BattleInterface {
    previewDependencies.battleUseCase
  }

  private var audioPlayer: any AudioPlayerInterface {
    previewDependencies.audioPlayer
  }

  private var analyticsUseCase: AnalyticsUseCase {
    previewDependencies.analyticsUseCase
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(view):
        return handleView(state: &state, action: view)
      case let .async(async):
        return handleAsync(state: &state, action: async)
      case let .inner(inner):
        return handleInner(state: &state, action: inner)
      case .delegate:
        return .none
      }
    }
  }
}

private extension ClassBattlePreviewFeature {
  func handleView(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      guard !state.isActive else { return .none }
      state.isActive = true
      analyticsUseCase.track(.screenView(screen: .classBattlePreview, referrer: .classRecommend))
      if let scenario = state.scenario {
        if state.isAudioReady {
          return .send(.async(.observeTime(state.instanceID)))
        }
        guard state.audioErrorMessage == nil,
              let url = audioURL(from: scenario)
        else { return .none }
        return .send(.async(.loadAudio(url)))
      }
      state.viewState = .loading
      return .send(.async(.fetchScenario(state.battle.id)))

    case .onDisappear:
      state.isActive = false
      state.isPlaying = false
      return stopEffects(instanceID: state.instanceID)

    case .backTapped:
      state.isActive = false
      state.isPlaying = false
      return .merge(stopEffects(instanceID: state.instanceID), .send(.delegate(.dismiss)))

    case .retryTapped:
      guard state.isActive else { return .none }
      state.viewState = .loading
      state.audioErrorMessage = nil
      return .send(.async(.fetchScenario(state.battle.id)))

    case .togglePlayTapped:
      guard state.isAudioReady else { return .none }
      if state.hasFinished {
        analyticsUseCase.track(.playbackAction(action: .replay, contentID: "\(state.battle.id)"))
        state.currentTime = 0
        state.hasFinished = false
        state.pendingSeekTime = 0
        state.isPlaying = true
        return .run { [player = audioPlayer] _ in
          await player.seek(to: 0)
          await player.play()
        }
      }
      state.isPlaying.toggle()
      let shouldPlay = state.isPlaying
      analyticsUseCase.track(.playbackAction(
        action: shouldPlay ? .play : .pause,
        contentID: "\(state.battle.id)"
      ))
      return .run { [player = audioPlayer] _ in
        if shouldPlay {
          await player.play()
        } else {
          await player.pause()
        }
      }

    case let .playbackRateSelected(rate):
      guard [Float(1), 1.25, 1.5, 2].contains(rate) else { return .none }
      state.playbackRate = rate
      return .run { [player = audioPlayer] _ in await player.setPlaybackRate(rate) }

    case .seekBackwardTapped:
      guard state.isAudioReady else { return .none }
      analyticsUseCase.track(.playbackAction(action: .skip15s, contentID: "\(state.battle.id)"))
      return seek(state: &state, to: state.currentTime - 15)

    case .seekForwardTapped:
      guard state.isAudioReady else { return .none }
      analyticsUseCase.track(.playbackAction(action: .skip15s, contentID: "\(state.battle.id)"))
      return seek(state: &state, to: state.currentTime + 15)

    case .replayTapped:
      guard state.isAudioReady else { return .none }
      analyticsUseCase.track(.playbackAction(action: .replay, contentID: "\(state.battle.id)"))
      state.currentTime = 0
      state.pendingSeekTime = 0
      state.hasFinished = false
      state.isPlaying = true
      return .run { [player = audioPlayer] _ in
        await player.seek(to: 0)
        await player.play()
      }

    case let .scrubbed(time):
      guard state.isAudioReady else { return .none }
      analyticsUseCase.track(.playbackAction(action: .seek, contentID: "\(state.battle.id)"))
      return seek(state: &state, to: time)
    }
  }

  func handleAsync(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case let .fetchScenario(battleID):
      return .run { [useCase = battleUseCase] send in
        let result = await Result { try await useCase.fetchScenario(battleId: battleID) }
          .mapError(BattleError.from)
        guard !Task.isCancelled else { return }
        await send(.inner(.scenarioResponse(result)))
      }
      .cancellable(id: CancelID.scenario(state.instanceID), cancelInFlight: true)

    case let .loadAudio(url):
      return .run { [player = audioPlayer, rate = state.playbackRate] send in
        let loaded = await player.load(url: url)
        guard !Task.isCancelled else { return }
        let duration = loaded ? await player.duration() : 0
        guard !Task.isCancelled else { return }
        await player.setPlaybackRate(rate)
        await send(.inner(.audioLoaded(loaded, duration)))
      }
      .cancellable(id: CancelID.audioLoad(state.instanceID), cancelInFlight: true)

    case let .observeTime(instanceID):
      return .run { [player = audioPlayer] send in
        for await time in player.currentTimes() {
          guard !Task.isCancelled else { return }
          await send(.inner(.playerTimeUpdated(time)))
        }
      }
      .cancellable(id: CancelID.audioObserver(instanceID), cancelInFlight: true)
    }
  }

  func handleInner(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    guard state.isActive else { return .none }
    switch action {
    case let .scenarioResponse(result):
      switch result {
      case let .success(scenario):
        state.scenario = scenario
        state.viewState = .loaded
        guard let url = audioURL(from: scenario) else {
          state.audioErrorMessage = "미리 들을 수 있는 음원이 없어요"
          analyticsUseCase.track(.classPreviewFailed(
            battleID: state.battle.id,
            reason: "missing_audio"
          ))
          return .none
        }
        return .send(.async(.loadAudio(url)))
      case .failure:
        state.viewState = .error
        analyticsUseCase.track(.classPreviewFailed(
          battleID: state.battle.id,
          reason: "scenario_fetch"
        ))
        return .none
      }

    case let .audioLoaded(loaded, duration):
      guard loaded else {
        state.audioErrorMessage = "오디오를 불러오지 못했어요"
        analyticsUseCase.track(.classPreviewFailed(
          battleID: state.battle.id,
          reason: "audio_load"
        ))
        return .none
      }
      state.isAudioReady = true
      state.audioDuration = duration > 0 ? duration : 60
      state.currentTime = 0
      state.isPlaying = true
      return .merge(
        .send(.async(.observeTime(state.instanceID))),
        .run { [player = audioPlayer] _ in await player.play() }
      )

    case let .playerTimeUpdated(time):
      guard state.isAudioReady else { return .none }
      if let target = state.pendingSeekTime {
        guard abs(time - target) < 0.5 * max(1, Double(state.playbackRate)) else { return .none }
        state.pendingSeekTime = nil
      }
      let limit = state.previewDuration
      state.currentTime = min(limit, max(0, time))
      let finishThreshold = state.audioDuration <= 60 ? max(0, limit - 0.3) : limit
      guard time >= finishThreshold else { return .none }
      state.isPlaying = false
      state.hasFinished = true
      return .run { [player = audioPlayer] _ in await player.pause() }
    }
  }

  func seek(
    state: inout State,
    to proposedTime: TimeInterval
  ) -> Effect<Action> {
    guard state.isAudioReady else { return .none }
    let target = min(state.previewDuration, max(0, proposedTime))
    state.currentTime = target
    state.pendingSeekTime = target
    if target < state.previewDuration {
      state.hasFinished = false
    }
    return .run { [player = audioPlayer] _ in await player.seek(to: target) }
  }

  func audioURL(from scenario: BattleScenario) -> URL? {
    guard let urlString = scenario.audios[scenario.recommendedPathKey.rawValue]
      ?? scenario.audios.values.first,
      let url = URL(string: urlString),
      ["http", "https"].contains(url.scheme?.lowercased() ?? "")
    else { return nil }
    return url
  }

  func stopEffects(instanceID: UUID) -> Effect<Action> {
    .merge(
      .cancel(id: CancelID.scenario(instanceID)),
      .cancel(id: CancelID.audioLoad(instanceID)),
      .cancel(id: CancelID.audioObserver(instanceID)),
      .run { [player = audioPlayer] _ in await player.pause() }
    )
  }
}
