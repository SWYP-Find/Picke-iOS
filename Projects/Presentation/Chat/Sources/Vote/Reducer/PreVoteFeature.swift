//
//  PreVoteFeature.swift
//  Home
//
//  Created by Wonji Suh on 5/16/26.
//

import Foundation
import UIKit

import BattleDomainInterface
import CommonDomainInterface
import ComposableArchitecture
import DomainInterface
import Entity
import LogMacro
import PerspectiveDomainInterface
import PickeDesignKit
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
    /// 배틀 상세(사전투표) 로드(디코딩/네트워크) 실패 여부. true 면 무한 스켈레톤 대신 오류+재시도 UI 를 노출한다.
    public var detailLoadFailed: Bool = false
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
    case retryTapped
    case shareTapped(snapshot: Data?)
    case optionTapped(optionId: Int)
    case primaryButtonTapped
  }

  public enum AsyncAction: Equatable {
    case fetchBattleDetail
    case fetchMyPerspective
    case deleteMyPerspective(perspectiveId: Int)
    case prepareShare(ShareContent)
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
    case voteSubmitted(battleId: Int, voteMode: VoteMode, result: PreVoteResult, isMindChanged: Bool)
    /// 이미 최종 투표(POST_VOTE)까지 마친 상태 — 댓글 화면으로 바로 이동.
    case alreadyFinalVoted(battleId: Int)
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
  @Dependency(\.analyticsUseCase) private var analyticsUseCase

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
      analyticsUseCase.track(.screenView(screen: .prevote, referrer: nil))
      var effects: [Effect<Action>] = []
      if state.battleDetail == nil, state.battle == nil, !state.isLoading {
        effects.append(.send(.async(.fetchBattleDetail)))
      }
      // 사전(pre) 진입 시에만 내 참여(perspective) 여부를 조회한다.
      // 이미 참여했으면 "다시 투표" 알럿 → 삭제 후 재투표.
      // 최종(post) 진입은 사전 참여가 이미 전제이므로 이 알럿이 뜨면 안 되고,
      // 알럿 presentation 이 공유 시트(.sheet) presentation 을 막는 문제도 생긴다.
      if state.voteMode == .pre, state.myPerspective == nil {
        effects.append(.send(.async(.fetchMyPerspective)))
      }
      return effects.isEmpty ? .none : .merge(effects)

    case .backButtonTapped:
      return .send(.delegate(.dismiss))

    case .retryTapped:
      return .send(.async(.fetchBattleDetail))

    case let .shareTapped(snapshot):
      let detail = state.battleDetail
      let battle = state.battle
      let title = detail?.battleInfo.title ?? battle?.titleLine1 ?? ""
      let url = detail?.shareUrl ?? "https://picke.store/battles/\(state.battleId)"
      let thumbnailURL = detail?.battleInfo.thumbnailUrl ?? battle?.backgroundImageURL
      let summary = {
        if let description = detail?.description, !description.isEmpty { return description }
        if let infoSummary = detail?.battleInfo.summary, !infoSummary.isEmpty { return infoSummary }
        return battle?.summary ?? ""
      }()
      let hashtags: [String] = {
        if let tags = detail?.categoryTags, !tags.isEmpty {
          return tags.map { "#\($0.name)" }
        }
        return battle?.tags ?? []
      }()
      let optionLine: String? = {
        guard let left = battle?.leftOption.stance,
              let right = battle?.rightOption.stance
        else { return nil }
        return "🆚 A: \(left)  vs  B: \(right)"
      }()
      let content = ShareContent(
        title: title,
        summary: summary,
        hashtags: hashtags,
        optionLine: optionLine,
        url: url,
        thumbnailURL: thumbnailURL,
        snapshotData: snapshot
      )
      return .send(.async(.prepareShare(content)))

    case let .optionTapped(optionId):
      state.selectedOptionId = (state.selectedOptionId == optionId) ? nil : optionId
      return .none

    case .primaryButtonTapped:
      guard let optionId = state.selectedOptionId else { return .none }
      switch state.voteMode {
      case .pre:
        state.isSubmitting = true
        return .send(.async(.submitPreVote(battleId: state.battleId, optionId: optionId)))
      case .post:
        state.isSubmitting = true
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
      state.detailLoadFailed = false
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

    case let .prepareShare(content):
      return .run { send in
        var items: [Any] = [content.displayText]

        if let url = URL(string: content.url) {
          items.append(url)
        } else {
          items.append(content.url)
        }

        if let data = content.snapshotData, let image = UIImage(data: data) {
          items.append(image)
        } else if let thumbnailURL = content.thumbnailURL,
                  let remoteURL = URL(string: thumbnailURL),
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
        state.detailLoadFailed = false
      case let .failure(error):
        state.detailLoadFailed = true
        Log.error("[PreVoteFeature] fetchBattle failed: \(error) — \(error.localizedDescription)")
      }
      return .none

    case let .myPerspectiveResponse(result):
      switch result {
      case let .success(perspective):
        state.myPerspective = perspective
        if perspective != nil {
          // 이미 참여한 배틀 — 팝업 없이 관점(댓글) 화면으로 바로 직행.
          return .send(.delegate(.alreadyFinalVoted(battleId: state.battleId)))
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
        analyticsUseCase.track(
          .battleStep(BattleStepData(stepName: .preVote, contentID: "\(state.battleId)"))
        )
        return .send(.delegate(.voteSubmitted(
          battleId: state.battleId,
          voteMode: .pre,
          result: voteResult,
          isMindChanged: false
        )))
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
        analyticsUseCase.track(
          .battleStep(BattleStepData(stepName: .postVote, contentID: "\(state.battleId)"))
        )
        let mindChanged = isMindChanged(state: state)
        return .send(.delegate(.voteSubmitted(
          battleId: state.battleId,
          voteMode: .post,
          result: voteResult,
          isMindChanged: mindChanged
        )))
      case let .failure(error):
        // 최종투표는 1회만 가능 — 이미 투표한 경우 서버가 500.
        // 재투표가 불가하므로 결과(댓글) 화면으로 이동한다.
        Log.error("[PreVoteFeature] submitPostVote failed: \(error.localizedDescription)")
        return .send(.delegate(.alreadyFinalVoted(battleId: state.battleId)))
      }
    }
  }

  /// pre 투표(기존 userVoteStatus: pro→옵션0 / con→옵션1) 대비 선택한 post 옵션이 다른 진영이면 true.
  /// post 제출 직전 시점이라 battleDetail.userVoteStatus 는 아직 pre 투표 값.
  private func isMindChanged(state: State) -> Bool {
    guard
      let detail = state.battleDetail,
      let postOptionId = state.selectedOptionId,
      detail.battleInfo.options.count >= 2
    else { return false }

    let preOptionId: Int? = switch detail.userVoteStatus {
    case .pro: detail.battleInfo.options[0].optionId
    case .con: detail.battleInfo.options[1].optionId
    default: nil
    }
    guard let preOptionId else { return false }
    return preOptionId != postOptionId
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
    case .dismiss, .voteSubmitted, .alreadyFinalVoted:
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
          // 이미 참여한 배틀에서 '취소' — 밖으로 나가지 않고 관점(댓글) 화면으로 이동.
          return .send(.delegate(.alreadyFinalVoted(battleId: state.battleId)))
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
