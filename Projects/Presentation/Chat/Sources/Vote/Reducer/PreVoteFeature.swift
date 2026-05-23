//
//  PreVoteFeature.swift
//  Home
//
//  Created by Wonji Suh on 5/16/26.
//

import Foundation
import UIKit

import ComposableArchitecture
import DesignSystem
import DomainInterface
import Entity
import LogMacro
import UseCase

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
    public var battleId: Int = 0
    public var voteMode: VoteMode = .pre
    public var myPerspective: BattlePerspective?
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?

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
      voteMode: VoteMode = .pre
    ) {
      self.battleId = battleId
      self.voteMode = voteMode
    }
  }

  /// 공유 시트 트리거. `.sheet(item:)` 에 바로 바인딩.
  public struct ShareItem: Equatable, Identifiable {
    public let id: UUID
    public let items: [Any]

    public init(
      id: UUID = UUID(),
      items: [Any]
    ) {
      self.id = id
      self.items = items
    }

    public static func == (lhs: ShareItem, rhs: ShareItem) -> Bool {
      lhs.id == rhs.id
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
    case backButtonTapped
    case shareTapped
    case optionTapped(optionId: Int)
    case primaryButtonTapped
  }

  public enum AsyncAction: Equatable {
    case fetchBattleDetail
    case fetchMyPerspective
    case deleteMyPerspective(perspectiveId: Int)
    case prepareShare(title: String, url: String, imageURL: String?)
    case submitPreVote(battleId: Int, optionId: Int)
    case submitPostVote(battleId: Int, optionId: Int)
  }

  public enum InnerAction: Equatable {
    case battleDetailResponse(Result<BattleDetail, BattleError>)
    case myPerspectiveResponse(Result<BattlePerspective?, BattleError>)
    case deleteMyPerspectiveResponse(Result<EmptyResult, PerspectiveError>)
    case preVoteResponse(Result<PreVoteResult, BattleError>)
    case sharePrepared(ShareItem)
    case postVoteResponse(Result<PreVoteResult, BattleError>)
  }

  public struct EmptyResult: Equatable {
    public init() {}
  }

  @CasePathable
  public enum ScopeAction: Equatable {
    case customAlert(PresentationAction<CustomAlertAction>)
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case voteSubmitted(battleId: Int, voteMode: VoteMode, result: PreVoteResult)
  }

  nonisolated enum CancelID: Hashable {
    case fetchBattleDetail
    case fetchMyPerspective
    case deleteMyPerspective
    case submitPreVote
    case submitPostVote
  }

  @Dependency(\.battleUseCase) private var battleUseCase
  @Dependency(\.perspectiveUseCase) private var perspectiveUseCase

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none

      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)

      case let .async(asyncAction):
        return handleAsyncAction(state: &state, action: asyncAction)

      case let .inner(innerAction):
        return handleInnerAction(state: &state, action: innerAction)

      case let .scope(scopeAction):
        return handleScopeAction(state: &state, action: scopeAction)

      case let .delegate(delegateAction):
        return handleDelegateAction(state: &state, action: delegateAction)
      }
    }
    .ifLet(\.$customAlert, action: \.scope.customAlert) {
      CustomConfirmAlert()
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
      var effects: [Effect<Action>] = []
      if state.battleDetail == nil, state.battle == nil, !state.isLoading {
        effects.append(.send(.async(.fetchBattleDetail)))
      }
      if state.voteMode == .pre, state.myPerspective == nil {
        effects.append(.send(.async(.fetchMyPerspective)))
      }
      return effects.isEmpty ? .none : .merge(effects)

    case .backButtonTapped:
      return .send(.delegate(.dismiss))

    case .shareTapped:
      let title = state.battleDetail?.battleInfo.title ?? state.battle?.titleLine1 ?? ""
      let url = state.battleDetail?.shareUrl
        ?? "https://picke.store/battles/\(state.battleId)"
      let imageURL = state.battleDetail?.battleInfo.thumbnailUrl ?? state.battle?.backgroundImageURL
      return .send(.async(.prepareShare(title: title, url: url, imageURL: imageURL)))

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
        return .send(.async(.submitPostVote(battleId: state.battleId, optionId: optionId)))
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
      return .run { [repository = battleUseCase] send in
        let result = await Result {
          try await repository.fetchBattle(battleId: battleId)
        }
        .mapError(BattleError.from)
        return await send(.inner(.battleDetailResponse(result)))
      }
      .cancellable(id: CancelID.fetchBattleDetail, cancelInFlight: true)

    case .fetchMyPerspective:
      let battleId = state.battleId
      return .run { [repository = battleUseCase] send in
        let result = await Result {
          try await repository.fetchMyPerspective(battleId: battleId)
        }
        .mapError(BattleError.from)
        return await send(.inner(.myPerspectiveResponse(result)))
      }
      .cancellable(id: CancelID.fetchMyPerspective, cancelInFlight: true)

    case let .deleteMyPerspective(perspectiveId):
      return .run { [repository = perspectiveUseCase] send in
        let result = await Result {
          try await repository.deletePerspective(perspectiveId: perspectiveId)
          return EmptyResult()
        }
        .mapError(PerspectiveError.from)
        return await send(.inner(.deleteMyPerspectiveResponse(result)))
      }
      .cancellable(id: CancelID.deleteMyPerspective, cancelInFlight: true)

    case let .prepareShare(title, url, imageURL):
      return .run { send in
        var items: [Any] = [title, url]

        if let imageURL,
           let remoteURL = URL(string: imageURL),
           let (data, _) = try? await URLSession.shared.data(from: remoteURL),
           let image = UIImage(data: data)
        {
          items.append(image)
        }

        await send(.inner(.sharePrepared(ShareItem(items: items))))
      }

    case let .submitPreVote(battleId, optionId):
      return .run { [repository = battleUseCase] send in
        let result = await Result {
          try await repository.submitPreVote(battleId: battleId, optionId: optionId)
        }
        .mapError(BattleError.from)
        return await send(.inner(.preVoteResponse(result)))
      }
      .cancellable(id: CancelID.submitPreVote, cancelInFlight: true)

    case let .submitPostVote(battleId, optionId):
      return .run { [repository = battleUseCase] send in
        let result = await Result {
          try await repository.submitPostVote(battleId: battleId, optionId: optionId)
        }
        .mapError(BattleError.from)
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

    case let .myPerspectiveResponse(result):
      switch result {
      case let .success(perspective):
        state.myPerspective = perspective
        if perspective != nil {
          state.customAlert = .alreadyWatched()
        }
      case let .failure(error):
        Log.error("[PreVoteFeature] fetchMyPerspective failed: \(error.localizedDescription)")
      }
      return .none

    case let .deleteMyPerspectiveResponse(result):
      switch result {
      case .success:
        state.myPerspective = nil
      case let .failure(error):
        Log.error("[PreVoteFeature] deleteMyPerspective failed: \(error.localizedDescription)")
      }
      return .none

    case let .preVoteResponse(result):
      state.isSubmitting = false
      switch result {
      case let .success(voteResult):
        return .send(.delegate(.voteSubmitted(battleId: state.battleId, voteMode: .pre, result: voteResult)))
      case let .failure(error):
        Log.error("[PreVoteFeature] submitPreVote failed: \(error.localizedDescription)")
        return .none
      }

    case let .sharePrepared(item):
      state.shareItem = item
      return .none

    case let .postVoteResponse(result):
      state.isSubmitting = false
      switch result {
      case let .success(voteResult):
        return .send(.delegate(.voteSubmitted(battleId: state.battleId, voteMode: .post, result: voteResult)))
      case let .failure(error):
        Log.error("[PreVoteFeature] submitPostVote failed: \(error.localizedDescription)")
        return .none
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
      return .none
    }
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
          let perspectiveId = state.myPerspective?.perspectiveId
          state.customAlert = nil
          guard let perspectiveId else { return .none }
          return .send(.async(.deleteMyPerspective(perspectiveId: perspectiveId)))

        case .cancelTapped:
          state.customAlert = nil
          return .send(.delegate(.dismiss))
        }

      case .dismiss:
        state.customAlert = nil
        return .none
      }
    }
  }
}

private extension Array {
  subscript(safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
