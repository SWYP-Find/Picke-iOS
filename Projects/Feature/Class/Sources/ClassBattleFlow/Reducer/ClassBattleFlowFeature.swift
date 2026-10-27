import AudioPlayerServiceInterface
import BattleDomainInterface
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import HomeDomainInterface
import PickeCoreUtility
import PerspectiveDomainInterface

@Reducer
public struct ClassBattleFlowFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var instanceID = UUID()
    public var room: ClassRoom?
    public var viewState: ClassBattleFlowViewState = .loading
    public var session: ClassBattleSession?
    public var voteHistory: ClassVoteHistory?
    public var voteStats: ClassVoteStats?
    public var opensResultsDirectly = false
    public var showsPreVoteLanding = false
    public var hasSubmittedInCurrentSession = false
    public var hasAdvancedInCurrentSession = false
    public var hasPublishedPerspective: Bool?
    public var selectedOptionID: Int?
    public var draft = ""
    public var perspectives: [ClassPerspectiveItem] = []
    public var nextPerspectiveCursor: String?
    public var hasMorePerspectives = false
    public var isLoadingPerspectives = false
    public var refreshAfterPerspectiveDetail = false
    public var perspectiveErrorMessage: String?
    public var errorMessage: String?
    public var loadRequestID: UUID?
    public var submitRequestID: UUID?
    public var audioRequestID: UUID?
    public var perspectiveRequestID: UUID?
    public var voteStatsRequestID: UUID?
    public var perspectiveLikeRequestID: UUID?
    public var myPerspectiveRequestID: UUID?
    public var isAudioReady = false
    public var isPlaying = false
    public var hasListened = false
    public var currentTime: TimeInterval = 0
    public var audioDuration: TimeInterval = 0
    public var playbackRate: Float = 1
    public var transcript: [ClassBattleTranscriptLine] = []
    public var selectedPerspectiveOptionID: Int?
    public var perspectiveSort: String = "popular"

    public init() {}

    public var step: ClassBattleStep? { session?.battle.currentStep }
    public var options: [ClassBattleOption] { session?.battle.options ?? [] }
    public var canParticipate: Bool { session?.canParticipate == true }

    public var canSubmit: Bool {
      guard viewState == .loaded, canParticipate, submitRequestID == nil else { return false }
      guard let step else { return false }
      switch step {
      case .none, .postVote: return selectedOptionID != nil
      case .preVote:
        guard selectedOptionID != nil else { return false }
        return selectedOptionID != voteHistory?.preVote.optionID || hasListened
      case .ttsListening: return hasListened
      case .completed:
        return !hasSubmittedInCurrentSession
          && hasPublishedPerspective == false
          && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      }
    }

    public var buttonTitle: String {
      guard let step else { return "불러오는 중" }
      switch step {
      case .none: return "사전 투표하기"
      case .preVote:
        return selectedOptionID != voteHistory?.preVote.optionID ? "사전투표 변경하기" : "청취 완료"
      case .ttsListening: return "청취 완료"
      case .postVote: return "최종 투표하기"
      case .completed:
        return "의견 등록하기"
      }
    }

    public var playbackRateTitle: String {
      playbackRate.formatted(.number.precision(.fractionLength(1...2)))
    }

    public var shouldShowOptions: Bool {
      guard let step else { return false }
      return [.none, .preVote, .postVote].contains(step)
    }

    public var shouldShowComposer: Bool {
      step == .some(.completed) && canParticipate
        && hasPublishedPerspective == false && !hasSubmittedInCurrentSession
    }

    public var isAudioStep: Bool {
      step == .some(.preVote) || step == .some(.ttsListening)
    }

    public var audioProgress: Double {
      guard audioDuration > 0 else { return 0 }
      return min(1, max(0, currentTime / audioDuration))
    }

    public var currentTimeText: String {
      Int(max(0, currentTime)).clockTimeText
    }

    public var audioDurationText: String {
      Int(max(0, audioDuration)).clockTimeText
    }

    public var visibleTranscript: [ClassBattleTranscriptLine] {
      transcript.filter { $0.startTime <= currentTime }
    }

    public var displayTitle: String {
      session?.battle.title ?? room?.battle.title ?? ""
    }

    public var displaySummary: String {
      session?.battle.summary ?? room?.battle.summary ?? ""
    }

    public var opinionChangeLabel: String? {
      guard let voteHistory else { return nil }
      guard let changed = voteHistory.opinionChanged
        ?? voteHistory.postVote.map({ $0.optionID != voteHistory.preVote.optionID }) else {
        return nil
      }
      return changed ? "생각이 바뀌었어요" : "처음 생각을 유지했어요"
    }

    public var displayArtworkURL: URL? {
      session?.battle.thumbnailURL ?? room?.battle.thumbnailURL
    }

    public var stageDescription: String {
      guard canParticipate else { return "클래스 참여 기간이 지나 진행 내용을 볼 수 있어요." }
      switch step {
      case .some(.none): return "먼저 생각과 가까운 입장을 선택해 주세요."
      case .some(.preVote): return "오디오를 끝까지 들은 뒤 다음 단계로 이동해요."
      case .some(.ttsListening): return "오디오를 끝까지 들은 뒤 다음 단계로 이동해요."
      case .some(.postVote): return "듣기 전과 생각이 달라졌나요? 다시 선택해 주세요."
      case .some(.completed):
        return shouldShowComposer ? "투표를 마쳤어요. 의견을 남겨 주세요." : "클래스 배틀 참여를 마쳤어요."
      case nil: return "클래스 배틀을 불러오는 중이에요."
      }
    }
  }

  public enum Action: ViewAction {
    case view(View)
    case inner(InnerAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View: Equatable {
    case onAppear
    case onDisappear
    case retryTapped
    case retryAudioTapped
    case loadMorePerspectivesTapped
    case retryMyPerspectiveTapped
    case backTapped
    case optionTapped(Int)
    case preVoteResultTapped
    case reportTapped
    case draftChanged(String)
    case submitTapped
    case playbackTapped
    case seekBy(TimeInterval)
    case scrub(TimeInterval)
    case replayTapped
    case playbackRateSelected(Float)
    case perspectiveOptionTapped(Int?)
    case perspectiveSortTapped(String)
    case perspectiveTapped(Int)
    case perspectiveLikeTapped(Int)
  }

  public enum InnerAction: Equatable {
    case progressResponse(UUID, Result<ClassBattleProgress, ClassBattleError>)
    case submissionResponse(UUID, ClassBattleStep, Result<Bool, ClassBattleError>)
    case audioURLResponse(UUID, Result<URL, ClassBattleError>)
    case transcriptLoaded(UUID, [ClassBattleTranscriptLine])
    case audioLoaded(UUID, Bool, TimeInterval)
    case playerTimeUpdated(UUID, TimeInterval)
    case perspectivePageResponse(UUID, Result<ClassPerspectivePage, ClassBattleError>)
    case voteStatsResponse(UUID, Result<ClassVoteStats, ClassBattleError>)
    case perspectiveLikeResponse(UUID, Int, Bool, Result<Bool, ClassBattleError>)
    case myPerspectiveResponse(UUID, Result<[ClassPerspectiveItem], ClassBattleError>)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case openReport(classID: Int)
    case openPerspective(Int)
  }

  public enum CancelID: Hashable, Sendable {
    case load(UUID)
    case submit(UUID)
    case audio(UUID)
    case time(UUID)
    case perspectives(UUID)
    case voteStats(UUID)
    case perspectiveLike(UUID)
    case myPerspective(UUID)
  }

  @Dependency(\.uuid) private var uuid
  @Dependency(\.classBattleUseCase) private var classUseCase
  @Dependency(\.battleUseCase) private var battleUseCase
  @Dependency(\.audioPlayer) private var audioPlayer
  @Dependency(\.perspectiveUseCase) private var perspectiveUseCase

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(viewAction): return handleView(state: &state, action: viewAction)
      case let .inner(innerAction): return handleInner(state: &state, action: innerAction)
      case .delegate: return .none
      }
    }
  }
}

extension ClassBattleFlowFeature {
  private func handleView(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      guard state.loadRequestID == nil else { return .none }
      if state.session == nil || state.viewState == .loading {
        return loadProgress(state: &state)
      }
      if state.isAudioStep, !state.showsPreVoteLanding,
         let battleID = state.session?.battle.id {
        if state.isAudioReady {
          return observePlayerTime(instanceID: state.instanceID)
        }
        return loadAudio(state: &state, battleID: battleID)
      }
      if state.step == .some(.completed), state.perspectiveRequestID == nil
      {
        let shouldRefresh = state.refreshAfterPerspectiveDetail
        state.refreshAfterPerspectiveDetail = false
        if shouldRefresh { state.hasSubmittedInCurrentSession = false }
        return .merge(
          state.perspectives.isEmpty || shouldRefresh
            ? loadPerspectives(state: &state, cursor: nil, preserveExisting: shouldRefresh) : .none,
          state.voteStats == nil ? loadVoteStats(state: &state) : .none,
          (state.hasPublishedPerspective == nil || shouldRefresh)
            && state.myPerspectiveRequestID == nil
            ? loadMyPerspectives(state: &state) : .none
        )
      }
      return .none
    case .onDisappear:
      if state.perspectiveLikeRequestID != nil {
        // A cancelled request may already have changed the server's like state.
        state.perspectives = []
      }
      if state.submitRequestID != nil {
        // The server may have accepted a request before its client effect was cancelled.
        state.viewState = .loading
        state.hasPublishedPerspective = nil
      }
      state.loadRequestID = nil
      state.submitRequestID = nil
      state.audioRequestID = nil
      state.perspectiveRequestID = nil
      state.perspectiveLikeRequestID = nil
      state.voteStatsRequestID = nil
      state.myPerspectiveRequestID = nil
      state.isLoadingPerspectives = false
      state.isPlaying = false
      return stopAudio(instanceID: state.instanceID)
    case .retryTapped:
      guard state.loadRequestID == nil else { return .none }
      return loadProgress(state: &state)
    case .retryAudioTapped:
      guard state.isAudioStep, !state.isAudioReady,
            let battleID = state.session?.battle.id else { return .none }
      return loadAudio(state: &state, battleID: battleID)
    case .loadMorePerspectivesTapped:
      guard state.step == .some(.completed), state.hasMorePerspectives,
            state.perspectiveRequestID == nil else { return .none }
      let cursor = state.nextPerspectiveCursor
      return loadPerspectives(state: &state, cursor: cursor)
    case .retryMyPerspectiveTapped:
      guard state.step == .some(.completed), state.hasPublishedPerspective == nil,
            state.myPerspectiveRequestID == nil else { return .none }
      state.perspectiveErrorMessage = nil
      return loadMyPerspectives(state: &state)
    case .backTapped:
      let instanceID = state.instanceID
      return .concatenate(
        stopAudio(instanceID: instanceID),
        .send(.delegate(.dismiss))
      )
    case let .optionTapped(optionID):
      guard state.canParticipate,
            let step = state.step,
            [.none, .preVote, .postVote].contains(step),
            state.options.contains(where: { $0.id == optionID }),
            state.submitRequestID == nil
      else { return .none }
      state.selectedOptionID = optionID
      state.errorMessage = nil
      return .none
    case .preVoteResultTapped:
      guard state.step == .some(.completed), state.showsPreVoteLanding else { return .none }
      state.showsPreVoteLanding = false
      return .none
    case .reportTapped:
      guard state.step == .some(.completed), state.submitRequestID == nil,
            let classID = state.room?.id else { return .none }
      return .send(.delegate(.openReport(classID: classID)))
    case let .draftChanged(text):
      state.draft = text
      state.errorMessage = nil
      return .none
    case .submitTapped:
      guard state.canSubmit else { return .none }
      guard let step = state.step else { return .none }
      let requestID = uuid()
      state.submitRequestID = requestID
      state.errorMessage = nil
      guard let classID = state.room?.id else { return .none }
      let optionID = state.selectedOptionID
      let preVoteOptionID = state.voteHistory?.preVote.optionID
      let draft = state.draft.trimmingCharacters(in: .whitespacesAndNewlines)
      return .run { [useCase = classUseCase] send in
        let result = await Result {
          switch step {
          case .none:
            guard let optionID else { throw ClassBattleError.invalidOption }
            _ = try await useCase.submitPreVote(classID: classID, optionID: optionID)
          case .preVote:
            if optionID != preVoteOptionID {
              guard let optionID else { throw ClassBattleError.invalidOption }
              _ = try await useCase.submitPreVote(classID: classID, optionID: optionID)
            } else {
              try await useCase.completeTTS(classID: classID)
            }
          case .ttsListening:
            try await useCase.completeTTS(classID: classID)
          case .postVote:
            guard let optionID else { throw ClassBattleError.invalidOption }
            _ = try await useCase.submitPostVote(classID: classID, optionID: optionID)
          case .completed:
            _ = try await useCase.publishPerspective(classID: classID, content: draft)
          }
          return true
        }.mapError(Self.mapError)
        guard !Task.isCancelled else { return }
        await send(.inner(.submissionResponse(requestID, step, result)))
      }
      .cancellable(id: CancelID.submit(state.instanceID), cancelInFlight: true)
    case .playbackTapped:
      guard state.isAudioStep, state.isAudioReady else { return .none }
      state.isPlaying.toggle()
      return .run { [player = audioPlayer, shouldPlay = state.isPlaying] _ in
        if shouldPlay { await player.play() } else { await player.pause() }
      }
    case let .seekBy(delta):
      guard state.isAudioStep, state.isAudioReady else { return .none }
      let target = min(state.audioDuration, max(0, state.currentTime + delta))
      state.currentTime = target
      return .run { [player = audioPlayer] _ in await player.seek(to: target) }
    case let .scrub(time):
      guard state.isAudioStep, state.isAudioReady, state.hasListened else { return .none }
      let target = min(state.audioDuration, max(0, time))
      state.currentTime = target
      return .run { [player = audioPlayer] _ in await player.seek(to: target) }
    case .replayTapped:
      guard state.isAudioStep, state.isAudioReady, state.hasListened else { return .none }
      state.currentTime = 0
      state.isPlaying = true
      return .run { [player = audioPlayer] _ in
        await player.seek(to: 0)
        await player.play()
      }
    case let .playbackRateSelected(rate):
      guard state.isAudioStep, state.isAudioReady else { return .none }
      state.playbackRate = rate
      return .run { [player = audioPlayer] _ in await player.setPlaybackRate(rate) }
    case let .perspectiveOptionTapped(optionID):
      guard state.step == .some(.completed), state.selectedPerspectiveOptionID != optionID else { return .none }
      state.selectedPerspectiveOptionID = optionID
      return loadPerspectives(state: &state, cursor: nil)
    case let .perspectiveSortTapped(sort):
      guard state.step == .some(.completed), ["popular", "latest"].contains(sort),
            state.perspectiveSort != sort else { return .none }
      state.perspectiveSort = sort
      return loadPerspectives(state: &state, cursor: nil)
    case let .perspectiveTapped(id):
      guard state.step == .some(.completed), state.submitRequestID == nil,
            state.perspectives.contains(where: { $0.id == id }) else { return .none }
      state.refreshAfterPerspectiveDetail = true
      return .send(.delegate(.openPerspective(id)))
    case let .perspectiveLikeTapped(id):
      guard state.step == .some(.completed), state.canParticipate,
            state.perspectiveLikeRequestID == nil,
            let item = state.perspectives.first(where: { $0.id == id }),
            item.isMyPerspective == false else { return .none }
      let requestID = uuid()
      state.perspectiveLikeRequestID = requestID
      return .run { [useCase = perspectiveUseCase, isLiked = item.isLiked] send in
        let result = await Result {
          if isLiked {
            _ = try await useCase.unlikePerspective(perspectiveId: id)
          } else {
            _ = try await useCase.likePerspective(perspectiveId: id)
          }
          return true
        }.mapError(Self.mapError)
        await send(.inner(.perspectiveLikeResponse(requestID, id, !isLiked, result)))
      }
      .cancellable(id: CancelID.perspectiveLike(state.instanceID), cancelInFlight: true)
    }
  }

  private func loadProgress(state: inout State) -> Effect<Action> {
    guard let classID = state.room?.id else { return .none }
    let requestID = uuid()
    state.loadRequestID = requestID
    state.viewState = .loading
    state.errorMessage = nil
    return .run { [useCase = classUseCase] send in
      let result = await Result {
        let session = try await useCase.fetchBattle(classID: classID)
        let history = session.battle.currentStep == .none
          ? nil
          : try await useCase.fetchMyVotes(classID: classID)
        return ClassBattleProgress(session: session, voteHistory: history)
      }.mapError(Self.mapError)
      guard !Task.isCancelled else { return }
      await send(.inner(.progressResponse(requestID, result)))
    }
    .cancellable(id: CancelID.load(state.instanceID), cancelInFlight: true)
  }

  private func handleInner(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .progressResponse(requestID, result):
      guard state.loadRequestID == requestID else { return .none }
      state.loadRequestID = nil
      switch result {
      case let .success(progress):
        state.viewState = .loaded
        state.session = progress.session
        state.voteHistory = progress.voteHistory
        if progress.session.battle.currentStep == .completed {
          if state.hasSubmittedInCurrentSession
            || (progress.session.commentRequired && progress.session.participationCompleted) {
            state.hasPublishedPerspective = true
          } else if progress.session.commentRequired {
            state.hasPublishedPerspective = false
          }
        }
        state.showsPreVoteLanding = progress.session.battle.currentStep == .completed
          && progress.session.participationCompleted
          && !state.opensResultsDirectly
          && !state.hasAdvancedInCurrentSession
        state.selectedOptionID = progress.session.battle.currentStep == .preVote
          ? progress.voteHistory?.preVote.optionID
          : progress.session.battle.currentStep == .completed
            ? progress.voteHistory?.postVote?.optionID
            : nil
        if state.isAudioStep, !state.showsPreVoteLanding {
          return loadAudio(state: &state, battleID: progress.session.battle.id)
        }
        if progress.session.battle.currentStep == .completed {
          return .merge(
            stopPlayback(instanceID: state.instanceID),
            loadPerspectives(state: &state, cursor: nil),
            loadVoteStats(state: &state),
            state.hasPublishedPerspective == nil ? loadMyPerspectives(state: &state) : .none
          )
        }
        return stopPlayback(instanceID: state.instanceID)
      case let .failure(error):
        state.viewState = .error
        state.errorMessage = error.message
        return .none
      }
    case let .submissionResponse(requestID, submittedStep, result):
      guard state.submitRequestID == requestID else { return .none }
      state.submitRequestID = nil
      switch result {
      case .success:
        state.draft = ""
        state.hasAdvancedInCurrentSession = true
        if submittedStep == .completed {
          state.hasSubmittedInCurrentSession = true
          state.hasPublishedPerspective = true
        }
        return loadProgress(state: &state)
      case let .failure(error):
        state.errorMessage = error.message
        return .none
      }
    case let .audioURLResponse(requestID, result):
      guard state.audioRequestID == requestID, state.isAudioStep else { return .none }
      switch result {
      case let .success(url):
        return .run { [player = audioPlayer] send in
          let loaded = await player.load(url: url)
          let duration = loaded ? await player.duration() : 0
          guard !Task.isCancelled else { return }
          await send(.inner(.audioLoaded(requestID, loaded, duration)))
        }
        .cancellable(id: CancelID.audio(state.instanceID), cancelInFlight: true)
      case let .failure(error):
        state.errorMessage = error.message
        state.audioRequestID = nil
        return .none
      }
    case let .audioLoaded(requestID, loaded, duration):
      guard state.audioRequestID == requestID, state.isAudioStep else { return .none }
      state.audioRequestID = nil
      guard loaded, duration > 0 else {
        state.errorMessage = "오디오를 재생할 수 없어요. 다시 시도해 주세요."
        return .none
      }
      state.isAudioReady = true
      state.audioDuration = duration
      state.isPlaying = true
      return .merge(
        .run { [player = audioPlayer] _ in await player.play() },
        observePlayerTime(instanceID: state.instanceID)
      )
    case let .transcriptLoaded(requestID, transcript):
      guard state.audioRequestID == requestID, state.isAudioStep else { return .none }
      state.transcript = transcript
      return .none
    case let .playerTimeUpdated(instanceID, time):
      guard state.instanceID == instanceID, state.isAudioStep,
            state.isAudioReady else { return .none }
      state.currentTime = min(state.audioDuration, max(0, time))
      guard time >= max(0, state.audioDuration - 0.3) else { return .none }
      state.hasListened = true
      guard state.isPlaying else { return .none }
      state.isPlaying = false
      return .run { [player = audioPlayer] _ in await player.pause() }
    case let .perspectivePageResponse(requestID, result):
      guard state.perspectiveRequestID == requestID else { return .none }
      state.perspectiveRequestID = nil
      state.isLoadingPerspectives = false
      switch result {
      case let .success(page):
        if state.nextPerspectiveCursor == nil {
          state.perspectives = page.items
        } else {
          state.perspectives.append(contentsOf: page.items)
        }
        state.nextPerspectiveCursor = page.nextCursor
        state.hasMorePerspectives = page.hasNext
        state.perspectiveErrorMessage = nil
      case let .failure(error):
        state.perspectiveErrorMessage = error.message
      }
      return .none
    case let .voteStatsResponse(requestID, result):
      guard state.voteStatsRequestID == requestID else { return .none }
      state.voteStatsRequestID = nil
      if case let .success(stats) = result {
        state.voteStats = stats
      }
      return .none
    case let .perspectiveLikeResponse(requestID, id, isLiked, result):
      guard state.perspectiveLikeRequestID == requestID else { return .none }
      state.perspectiveLikeRequestID = nil
      switch result {
      case .success:
        if let index = state.perspectives.firstIndex(where: { $0.id == id }) {
          let item = state.perspectives[index]
          state.perspectives[index] = ClassPerspectiveItem(
            id: item.id,
            author: item.author,
            option: item.option,
            content: item.content,
            likeCount: max(0, item.likeCount + (isLiked ? 1 : -1)),
            commentCount: item.commentCount,
            isLiked: isLiked,
            isMyPerspective: item.isMyPerspective,
            status: item.status,
            createdAt: item.createdAt
          )
        }
        return .none
      case let .failure(error):
        state.perspectiveErrorMessage = error.message
        return .none
      }
    case let .myPerspectiveResponse(requestID, result):
      guard state.myPerspectiveRequestID == requestID else { return .none }
      state.myPerspectiveRequestID = nil
      switch result {
      case let .success(items):
        state.hasPublishedPerspective = !items.isEmpty || state.hasSubmittedInCurrentSession
      case let .failure(error):
        state.perspectiveErrorMessage = error.message
      }
      return .none
    }
  }

  private func loadMyPerspectives(state: inout State) -> Effect<Action> {
    guard let classID = state.room?.id else { return .none }
    let requestID = uuid()
    state.myPerspectiveRequestID = requestID
    return .run { [useCase = classUseCase] send in
      let result = await Result {
        try await useCase.fetchMyPerspectives(classID: classID)
      }.mapError(Self.mapError)
      guard !Task.isCancelled else { return }
      await send(.inner(.myPerspectiveResponse(requestID, result)))
    }
    .cancellable(id: CancelID.myPerspective(state.instanceID), cancelInFlight: true)
  }

  private func loadVoteStats(state: inout State) -> Effect<Action> {
    guard let classID = state.room?.id else { return .none }
    let requestID = uuid()
    state.voteStatsRequestID = requestID
    return .run { [useCase = classUseCase] send in
      let result = await Result {
        try await useCase.fetchVoteStats(classID: classID)
      }.mapError(Self.mapError)
      guard !Task.isCancelled else { return }
      await send(.inner(.voteStatsResponse(requestID, result)))
    }
    .cancellable(id: CancelID.voteStats(state.instanceID), cancelInFlight: true)
  }

  private func loadPerspectives(
    state: inout State,
    cursor: String?,
    preserveExisting: Bool = false
  ) -> Effect<Action> {
    guard let classID = state.room?.id else { return .none }
    let requestID = uuid()
    state.perspectiveRequestID = requestID
    state.isLoadingPerspectives = true
    state.perspectiveErrorMessage = nil
    if cursor == nil {
      state.nextPerspectiveCursor = nil
      if !preserveExisting { state.perspectives = [] }
    }
    let optionID = state.selectedPerspectiveOptionID
    let sort = state.perspectiveSort
    return .run { [useCase = classUseCase] send in
      let result = await Result {
        try await useCase.fetchPerspectives(
          classID: classID,
          cursor: cursor,
          size: nil,
          optionID: optionID,
          sort: sort
        )
      }.mapError(Self.mapError)
      guard !Task.isCancelled else { return }
      await send(.inner(.perspectivePageResponse(requestID, result)))
    }
    .cancellable(id: CancelID.perspectives(state.instanceID), cancelInFlight: true)
  }

  private func loadAudio(
    state: inout State,
    battleID: Int
  ) -> Effect<Action> {
    guard !state.isAudioReady, state.audioRequestID == nil else { return .none }
    let requestID = uuid()
    state.audioRequestID = requestID
    state.errorMessage = nil
    return .run { [useCase = battleUseCase] send in
      let result = await Result {
        let scenario = try await useCase.fetchScenario(battleId: battleID)
        guard let rawURL = scenario.audios[scenario.recommendedPathKey.rawValue]
          ?? scenario.audios.values.first,
          let url = URL(string: rawURL),
          ["http", "https"].contains(url.scheme?.lowercased() ?? "")
        else { throw ClassBattleError.invalidResponse }
        var transcript: [ClassBattleTranscriptLine] = []
        var visibleNodeID = scenario.startNodeId
        var visitedNodeIDs = Set<Int>()
        while !visitedNodeIDs.contains(visibleNodeID) {
          guard let node = scenario.nodes.first(where: { $0.nodeId == visibleNodeID }) else { break }
          visitedNodeIDs.insert(visibleNodeID)
          let scripts = node.scripts
          let firstStartMs = scripts.map(\.startTimeMs).min() ?? 0
          let hasDistinctStarts = Set(scripts.map(\.startTimeMs)).count > 1
          func revealStart(_ index: Int) -> Int {
            hasDistinctStarts
              ? scripts[index].startTimeMs
              : firstStartMs + node.audioDuration * 1000 * index / max(1, scripts.count)
          }
          for (index, script) in scripts.enumerated() {
            let startMs = revealStart(index)
            let endMs = index + 1 < scripts.count
              ? revealStart(index + 1)
              : firstStartMs + node.audioDuration * 1000
            let side: String
            switch script.speakerType {
            case .a: side = "A"
            case .b: side = "B"
            case .narrator: side = "NARRATOR"
            case .philosopher, .unknown:
              side = scenario.philosophers.first(where: { $0.name == script.speakerName })?.label ?? "NARRATOR"
            }
            let philosopher = scenario.philosophers.first(where: { $0.label == side })
            let speakerName = philosopher?.name ?? script.speakerName
            let sentences = script.text.splitIntoSentences()
              .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
              .filter { !$0.isEmpty }
            let parts = sentences.isEmpty ? [script.text] : sentences
            let totalCharacters = max(1, parts.reduce(0) { $0 + $1.count })
            var previousCharacters = 0
            for sentence in parts {
              let sentenceStartMs = startMs
                + max(1, endMs - startMs) * previousCharacters / totalCharacters
              previousCharacters += sentence.count
              transcript.append(ClassBattleTranscriptLine(
                id: transcript.count,
                startTime: Double(sentenceStartMs) / 1000,
                speakerName: speakerName,
                speakerImageURL: philosopher?.imageUrl,
                text: sentence,
                side: side
              ))
            }
          }
          guard let nextNodeID = scenario.nextNodeId(for: node) else { break }
          visibleNodeID = nextNodeID
        }
        return (url, transcript)
      }.mapError(Self.mapError)
      guard !Task.isCancelled else { return }
      switch result {
      case let .success((url, transcript)):
        if !transcript.isEmpty {
          await send(.inner(.transcriptLoaded(requestID, transcript)))
        }
        await send(.inner(.audioURLResponse(requestID, .success(url))))
      case let .failure(error):
        await send(.inner(.audioURLResponse(requestID, .failure(error))))
      }
    }
    .cancellable(id: CancelID.audio(state.instanceID), cancelInFlight: true)
  }

  private func observePlayerTime(instanceID: UUID) -> Effect<Action> {
    .run { [player = audioPlayer] send in
      for await time in player.currentTimes() {
        guard !Task.isCancelled else { return }
        await send(.inner(.playerTimeUpdated(instanceID, time)))
      }
    }
    .cancellable(id: CancelID.time(instanceID), cancelInFlight: true)
  }

  private func stopAudio(instanceID: UUID) -> Effect<Action> {
    .merge(
      .cancel(id: CancelID.load(instanceID)),
      .cancel(id: CancelID.submit(instanceID)),
      .cancel(id: CancelID.perspectives(instanceID)),
      .cancel(id: CancelID.perspectiveLike(instanceID)),
      .cancel(id: CancelID.myPerspective(instanceID)),
      .cancel(id: CancelID.voteStats(instanceID)),
      stopPlayback(instanceID: instanceID)
    )
  }

  private func stopPlayback(instanceID: UUID) -> Effect<Action> {
    .merge(
      .cancel(id: CancelID.audio(instanceID)),
      .cancel(id: CancelID.time(instanceID)),
      .run { [player = audioPlayer] _ in await player.pause() }
    )
  }

  private static func mapError(_ error: Error) -> ClassBattleError {
    (error as? ClassBattleError) ?? .network(error.localizedDescription)
  }
}
