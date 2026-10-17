//
//  ClassAIVoteFeature.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import BattleDomainInterface
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeCoreUtility

@Reducer
public struct ClassAIVoteFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public let instanceID: UUID
    public let room: ClassRoom
    public let battleID: Int
    public var selectedOptionID: Int?
    public var hasSubmitted = false
    public var hasCompletedPostVote = false
    public var isSubmitting = false
    public var viewState: ViewState = .loading
    public var loadRequestID: UUID?
    public var submitRequestID: UUID?
    public var errorMessage: String?

    public init(
      room: ClassRoom,
      battleID: Int,
      instanceID: UUID? = nil
    ) {
      @Dependency(\.uuid) var uuid
      self.instanceID = instanceID ?? uuid()
      self.room = room
      self.battleID = battleID
    }

    public enum ViewState: Equatable {
      case loading, error, loaded
    }

    public var submitTitle: String {
      hasSubmitted ? "의견 보기" : "투표하기"
    }

    public var canSubmit: Bool {
      viewState == .loaded && selectedOptionID != nil && !isSubmitting
    }

    public var categoryTitle: String { "#\(room.battle.categoryDisplayTitle)" }

    public var commentCountTitle: String? {
      guard room.battle.commentCount > 0 else { return nil }
      return String(room.battle.commentCount)
    }

    public var commentAccessibilityLabel: String { "댓글 \(room.battle.commentCount)개" }

    public var deadlineTitle: String {
      guard room.deadline != .distantFuture else { return "마감일 없음" }
      return room.deadline.formatted(.dottedDateTimeWithWeekday) + "까지"
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
    case retryTapped
    case backTapped
    case optionTapped(Int)
    case submitTapped
  }

  public struct VoteProgress: Equatable {
    public let status: UserVoteStatus
    public let step: BattleStep

    public init(
      status: UserVoteStatus,
      step: BattleStep
    ) {
      self.status = status
      self.step = step
    }
  }

  public enum InnerAction: Equatable {
    case voteLoaded(instanceID: UUID, requestID: UUID, battleID: Int, Result<VoteProgress, BattleError>)
    case voteSubmitted(instanceID: UUID, requestID: UUID, battleID: Int, Result<PreVoteResult, BattleError>)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case voteSubmitted(battleID: Int, selectedOptionID: Int, hasCompletedPostVote: Bool)
  }

  public enum CancelID: Hashable, Sendable {
    case load(UUID)
    case submit(UUID)
  }

  @Dependency(\.uuid) private var uuid
  @Dependency(\.battleUseCase) private var battleUseCase

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)
      case let .inner(innerAction):
        return handleInnerAction(state: &state, action: innerAction)
      case .delegate:
        return .none
      }
    }
  }
}

// MARK: - Action Handlers

extension ClassAIVoteFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      guard state.viewState != .loaded, state.loadRequestID == nil else { return .none }
      return loadVote(state: &state)

    case .retryTapped:
      guard state.viewState == .error, state.loadRequestID == nil else { return .none }
      return loadVote(state: &state)

    case .backTapped:
      state.loadRequestID = nil
      state.submitRequestID = nil
      state.isSubmitting = false
      return .concatenate(
        .merge(
          .cancel(id: CancelID.load(state.instanceID)),
          .cancel(id: CancelID.submit(state.instanceID))
        ),
        .send(.delegate(.dismiss))
      )

    case let .optionTapped(optionID):
      guard state.viewState == .loaded, !state.hasSubmitted, !state.isSubmitting,
            optionID == 1 || optionID == 2
      else {
        return .none
      }
      state.selectedOptionID = optionID
      state.errorMessage = nil
      return .none

    case .submitTapped:
      guard state.canSubmit, let optionID = state.selectedOptionID else { return .none }
      if state.hasSubmitted {
        return .send(.delegate(.voteSubmitted(
          battleID: state.battleID,
          selectedOptionID: optionID,
          hasCompletedPostVote: state.hasCompletedPostVote
        )))
      }
      state.isSubmitting = true
      state.errorMessage = nil
      let requestID = uuid()
      state.submitRequestID = requestID
      return .run { [battleUseCase, instanceID = state.instanceID, battleID = state.battleID] send in
        let result = await Result {
          try await battleUseCase.submitPreVote(battleId: battleID, optionId: optionID)
        }.mapError(BattleError.from)
        guard !Task.isCancelled else { return }
        await send(.inner(.voteSubmitted(
          instanceID: instanceID,
          requestID: requestID,
          battleID: battleID,
          result
        )))
      }
      .cancellable(id: CancelID.submit(state.instanceID), cancelInFlight: true)
    }
  }

  private func loadVote(state: inout State) -> Effect<Action> {
    let requestID = uuid()
    state.loadRequestID = requestID
    state.viewState = .loading
    state.errorMessage = nil
    return .run { [battleUseCase, instanceID = state.instanceID, battleID = state.battleID] send in
      let result = await Result {
        let battle = try await battleUseCase.fetchBattle(battleId: battleID)
        return VoteProgress(status: battle.userVoteStatus, step: battle.currentStep)
      }.mapError(BattleError.from)
      guard !Task.isCancelled else { return }
      await send(.inner(.voteLoaded(
        instanceID: instanceID,
        requestID: requestID,
        battleID: battleID,
        result
      )))
    }
    .cancellable(id: CancelID.load(state.instanceID), cancelInFlight: true)
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .voteLoaded(instanceID, requestID, battleID, result):
      guard state.instanceID == instanceID, state.loadRequestID == requestID,
            state.battleID == battleID else { return .none }
      state.loadRequestID = nil
      switch result {
      case let .success(progress):
        state.viewState = .loaded
        switch progress.status {
        case .pro:
          state.selectedOptionID = 1
          state.hasSubmitted = true
        case .con:
          state.selectedOptionID = 2
          state.hasSubmitted = true
        case .none, .unknown:
          state.selectedOptionID = nil
          state.hasSubmitted = false
        }
        state.hasCompletedPostVote = progress.step == .finished || progress.step == .completed
      case .failure:
        state.viewState = .error
        state.errorMessage = "투표 상태를 불러오지 못했어요. 다시 시도해 주세요."
      }
      return .none

    case let .voteSubmitted(instanceID, requestID, battleID, result):
      guard state.instanceID == instanceID, state.submitRequestID == requestID,
            state.battleID == battleID else { return .none }
      state.submitRequestID = nil
      state.isSubmitting = false
      switch result {
      case .success:
        state.hasSubmitted = true
        guard let optionID = state.selectedOptionID else { return .none }
        return .send(.delegate(.voteSubmitted(
          battleID: state.battleID,
          selectedOptionID: optionID,
          hasCompletedPostVote: false
        )))
      case .failure:
        state.errorMessage = "투표를 저장하지 못했어요. 다시 시도해 주세요."
        return .none
      }
    }
  }
}
