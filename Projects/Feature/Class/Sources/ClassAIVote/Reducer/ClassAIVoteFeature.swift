//
//  ClassAIVoteFeature.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import BattleDomainInterface
import ClassDomainInterface
import ComposableArchitecture

@Reducer
public struct ClassAIVoteFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public let room: ClassRoom
    public let battleID: Int
    public var selectedOptionID: Int?
    public var hasSubmitted = false
    public var hasCompletedPostVote = false
    public var isSubmitting = false
    public var errorMessage: String?

    public init(
      room: ClassRoom,
      battleID: Int
    ) {
      self.room = room
      self.battleID = battleID
    }

    public var canSubmit: Bool {
      selectedOptionID != nil && !isSubmitting
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
    case voteLoaded(Result<VoteProgress, BattleError>)
    case voteSubmitted(Result<PreVoteResult, BattleError>)
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
    case voteSubmitted(battleID: Int, selectedOptionID: Int, hasCompletedPostVote: Bool)
  }

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
      let battleID = state.battleID
      return .run { send in
        do {
          let battle = try await battleUseCase.fetchBattle(battleId: battleID)
          await send(.inner(.voteLoaded(.success(.init(
            status: battle.userVoteStatus,
            step: battle.currentStep
          )))))
        } catch {
          await send(.inner(.voteLoaded(.failure(BattleError.from(error)))))
        }
      }

    case .backTapped:
      return .send(.delegate(.dismiss))

    case let .optionTapped(optionID):
      guard !state.hasSubmitted, !state.isSubmitting, optionID == 1 || optionID == 2 else {
        return .none
      }
      state.selectedOptionID = optionID
      state.errorMessage = nil
      return .none

    case .submitTapped:
      guard let optionID = state.selectedOptionID, !state.isSubmitting else { return .none }
      if state.hasSubmitted {
        return .send(.delegate(.voteSubmitted(
          battleID: state.battleID,
          selectedOptionID: optionID,
          hasCompletedPostVote: state.hasCompletedPostVote
        )))
      }
      state.isSubmitting = true
      state.errorMessage = nil
      let battleID = state.battleID
      return .run { send in
        do {
          let result = try await battleUseCase.submitPreVote(battleId: battleID, optionId: optionID)
          await send(.inner(.voteSubmitted(.success(result))))
        } catch {
          await send(.inner(.voteSubmitted(.failure(BattleError.from(error)))))
        }
      }
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .voteLoaded(.success(progress)):
      switch progress.status {
      case .pro:
        state.selectedOptionID = 1
        state.hasSubmitted = true
      case .con:
        state.selectedOptionID = 2
        state.hasSubmitted = true
      case .none, .unknown:
        break
      }
      state.hasCompletedPostVote = progress.step == .finished || progress.step == .completed
      return .none

    case .voteLoaded(.failure):
      state.errorMessage = "투표 상태를 불러오지 못했어요. 다시 시도해 주세요."
      return .none

    case .voteSubmitted(.success):
      state.isSubmitting = false
      state.hasSubmitted = true
      guard let optionID = state.selectedOptionID else { return .none }
      return .send(.delegate(.voteSubmitted(
        battleID: state.battleID,
        selectedOptionID: optionID,
        hasCompletedPostVote: false
      )))

    case .voteSubmitted(.failure):
      state.isSubmitting = false
      state.errorMessage = "투표를 저장하지 못했어요. 다시 시도해 주세요."
      return .none
    }
  }
}
