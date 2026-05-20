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

  @ObservableState
  public struct State: Equatable {
    public var battle: PreVoteBattle = .mock
    public var battleDetail: BattleDetail?
    public var selectedSide: PhilosopherAvatar?
    public var isLoading: Bool = false
    public var isSubmitting: Bool = false
    public var shareItem: ShareItem?
    public var battleId: Int

    public var isPrimaryButtonEnabled: Bool {
      selectedSide != nil && !isSubmitting
    }

    public init(battleId: Int = 0) {
      self.battleId = battleId
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
    case optionTapped(PhilosopherAvatar)
    case primaryButtonTapped
  }

  public enum AsyncAction: Equatable {
    case fetchBattleDetail
    case submitPreVote(battleId: Int, optionId: Int)
  }

  public enum InnerAction: Equatable {
    case battleDetailResponse(Result<BattleDetail, AuthError>)
    case preVoteResponse(Result<PreVoteResult, AuthError>)
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case voteSubmitted(battleId: Int, result: PreVoteResult)
  }

  nonisolated enum CancelID: Hashable {
    case fetchBattleDetail
    case submitPreVote
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
      guard state.battleDetail == nil, !state.isLoading else { return .none }
      return .send(.async(.fetchBattleDetail))

    case .backButtonTapped:
      return .send(.delegate(.dismiss))

    case .shareTapped:
      let title = state.battleDetail?.battleInfo.title ?? state.battle.titleLine1
      let url = state.battleDetail?.shareUrl
        ?? "https://picke.store/battles/\(state.battleId)"
      state.shareItem = ShareItem(items: [title, url])
      return .none

    case let .optionTapped(side):
      state.selectedSide = (state.selectedSide == side) ? nil : side
      return .none

    case .primaryButtonTapped:
      guard let side = state.selectedSide else { return .none }
      guard let optionId = optionId(for: side, in: state.battle) else {
        Log.error("[PreVoteFeature] optionId 매핑 실패 side=\(side)")
        return .none
      }
      state.isSubmitting = true
      return .send(.async(.submitPreVote(battleId: state.battleId, optionId: optionId)))
    }
  }

  private func optionId(
    for side: PhilosopherAvatar,
    in battle: PreVoteBattle
  ) -> Int? {
    if battle.leftOption.philosopher == side { return battle.leftOption.optionId }
    if battle.rightOption.philosopher == side { return battle.rightOption.optionId }
    return nil
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
        state.battle = makeBattle(from: detail, fallback: state.battle)
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
    }
  }

  /// API 로 받은 BattleDetail 을 화면 모델 PreVoteBattle 로 매핑.
  /// 옵션 0, 1 만 좌/우 카드에 매핑 (label A→left, B→right).
  private func makeBattle(
    from detail: BattleDetail,
    fallback: PreVoteBattle
  ) -> PreVoteBattle {
    let info = detail.battleInfo
    let philosophers: [PhilosopherAvatar] = [.plato, .sartre, .sunja]
    let mapped = info.options.enumerated().map { idx, option in
      PreVoteOption(
        optionId: option.optionId,
        philosopher: avatar(for: option.representative)
          ?? philosophers[safe: idx]
          ?? .plato,
        stance: option.title
      )
    }
    let leftOption = mapped[safe: 0] ?? fallback.leftOption
    let rightOption = mapped[safe: 1] ?? fallback.rightOption

    return PreVoteBattle(
      battleId: info.battleId,
      backgroundImageURL: info.thumbnailUrl.isEmpty ? fallback.backgroundImageURL : info.thumbnailUrl,
      tags: detail.categoryTags.map { "#\($0.name)" },
      titleLine1: info.title,
      titleLine2: "",
      summary: detail.description.isEmpty ? info.summary : detail.description,
      leftOption: leftOption,
      rightOption: rightOption
    )
  }

  private func avatar(for representative: String) -> PhilosopherAvatar? {
    PhilosopherAvatar.allCases.first { $0.rawValue == representative }
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
