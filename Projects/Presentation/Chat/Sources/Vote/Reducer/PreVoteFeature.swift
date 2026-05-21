//
//  PreVoteFeature.swift
//  Home
//
//  Created by Wonji Suh on 5/16/26.
//

import Foundation

import ComposableArchitecture
import DomainInterface
import Entity
import LogMacro

@Reducer
public struct PreVoteFeature {
  public init() {}

  public enum VoteMode: Equatable {
    case pre
    case post
  }

  @ObservableState
  public struct State: Equatable {
    public var battle: PreVoteBattle?
    public var battleDetail: BattleDetail?
    public var selectedOptionId: Int?
    public var isLoading: Bool = false
    public var isSubmitting: Bool = false
    public var shareItem: ShareItem?
    public var battleId: Int
    public var voteMode: VoteMode

    public var isPrimaryButtonEnabled: Bool {
      selectedOptionId != nil && !isSubmitting
    }

    public var primaryButtonTitle: String {
      switch voteMode {
      case .pre: "사전 투표하기"
      case .post: "최종 투표하기"
      }
    }

    public init(
      battleId: Int = 0,
      battle: PreVoteBattle? = nil,
      voteMode: VoteMode = .pre
    ) {
      self.battleId = battleId
      self.battle = battle
      self.voteMode = voteMode
    }
  }

  /// 공유 시트 트리거. `.sheet(item:)` 에 바로 바인딩.
  public struct ShareItem: Equatable, Identifiable {
    public let id: UUID
    public let items: [String]

    public init(id: UUID = UUID(), items: [String]) {
      self.id = id
      self.items = items
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
    case shareTapped
    case optionTapped(optionId: Int)
    case primaryButtonTapped
  }

  public enum AsyncAction: Equatable {
    case fetchBattleDetail
    case submitPreVote(battleId: Int, optionId: Int)
    case submitPostVote(battleId: Int, optionId: Int)
  }

  public enum InnerAction: Equatable {
    case battleDetailResponse(Result<BattleDetail, AuthError>)
    case preVoteResponse(Result<PreVoteResult, AuthError>)
    case postVoteResponse(Result<PreVoteResult, AuthError>)
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case voteSubmitted(battleId: Int, result: PreVoteResult)
  }

  nonisolated enum CancelID: Hashable {
    case fetchBattleDetail
    case submitPreVote
    case submitPostVote
  }

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

extension PreVoteFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      guard state.battleDetail == nil,
            state.battle == nil,
            !state.isLoading
      else { return .none }
      return .send(.async(.fetchBattleDetail))

    case .backButtonTapped:
      return .send(.delegate(.dismiss))

    case .shareTapped:
      let title = state.battleDetail?.battleInfo.title ?? state.battle?.titleLine1 ?? ""
      let url = state.battleDetail?.shareUrl
        ?? "https://picke.store/battles/\(state.battleId)"
      state.shareItem = ShareItem(items: [title, url])
      return .none

    case let .optionTapped(optionId):
      state.selectedOptionId = (state.selectedOptionId == optionId) ? nil : optionId
      return .none

    case .primaryButtonTapped:
      guard let optionId = state.selectedOptionId else { return .none }
      state.isSubmitting = true
      switch state.voteMode {
      case .pre:
        return .send(.async(.submitPreVote(battleId: state.battleId, optionId: optionId)))
      case .post:
        return .none
      }
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetchBattleDetail:
      state.isLoading = true
      let battleId = state.battleId
      return .run { [repository = battleRepository] send in
        let result = await Result {
          try await repository.fetchBattle(battleId: battleId)
        }
        .mapError(AuthError.from)
        return await send(.inner(.battleDetailResponse(result)))
      }
      .cancellable(id: CancelID.fetchBattleDetail, cancelInFlight: true)

    case let .submitPreVote(battleId, optionId):
      return .run { [repository = battleRepository] send in
        let result = await Result {
          try await repository.submitPreVote(battleId: battleId, optionId: optionId)
        }
        .mapError(AuthError.from)
        return await send(.inner(.preVoteResponse(result)))
      }
      .cancellable(id: CancelID.submitPreVote, cancelInFlight: true)

    case let .submitPostVote(battleId, optionId):
      return .run { [repository = battleRepository] send in
        let result = await Result {
          try await repository.submitPostVote(battleId: battleId, optionId: optionId)
        }
        .mapError(AuthError.from)
        return await send(.inner(.postVoteResponse(result)))
      }
      .cancellable(id: CancelID.submitPostVote, cancelInFlight: true)
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .battleDetailResponse(result):
      state.isLoading = false
      switch result {
      case let .success(detail):
        state.battleDetail = detail
        state.battle = makeBattle(from: detail)
      case let .failure(error):
        Log.error("[PreVoteFeature] fetchBattle failed: \(error.localizedDescription)")
      }
      return .none

    case let .preVoteResponse(result):
      state.isSubmitting = false
      switch result {
      case let .success(voteResult):
        return .send(.delegate(.voteSubmitted(battleId: state.battleId, result: voteResult)))
      case let .failure(error):
        Log.error("[PreVoteFeature] submitPreVote failed: \(error.localizedDescription)")
        return .send(.delegate(.voteSubmitted(battleId: state.battleId, result: .init(voteId: 0, status: .created))))
      }

    case let .postVoteResponse(result):
      state.isSubmitting = false
      switch result {
      case let .success(voteResult):
        return .send(.delegate(.voteSubmitted(battleId: state.battleId, result: voteResult)))
      case let .failure(error):
        Log.error("[PreVoteFeature] submitPostVote failed: \(error.localizedDescription)")
        return .send(.delegate(.voteSubmitted(battleId: state.battleId, result: .init(voteId: 0, status: .created))))
      }
    }
  }

  /// API 로 받은 BattleDetail 을 화면 모델 PreVoteBattle 로 매핑.
  /// 옵션 0, 1 만 좌/우 카드에 매핑 (label A→left, B→right).
  private func makeBattle(from detail: BattleDetail) -> PreVoteBattle? {
    let info = detail.battleInfo
    let mapped = info.options.map { option in
      PreVoteOption(
        optionId: option.optionId,
        representative: option.representative,
        imageURL: option.imageUrl,
        stance: option.title
      )
    }
    guard let leftOption = mapped[safe: 0],
          let rightOption = mapped[safe: 1]
    else {
      Log.error("[PreVoteFeature] 서버 option 데이터 부족 count=\(mapped.count)")
      return nil
    }

    return PreVoteBattle(
      battleId: info.battleId,
      backgroundImageURL: info.thumbnailUrl,
      tags: detail.categoryTags.map { "#\($0.name)" },
      titleLine1: info.title,
      titleLine2: "",
      summary: detail.description.isEmpty ? info.summary : detail.description,
      leftOption: leftOption,
      rightOption: rightOption
    )
  }

  private func handleDelegateAction(
    state _: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
    case .dismiss, .voteSubmitted:
      .none
    }
  }
}

private extension Array {
  subscript(safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
