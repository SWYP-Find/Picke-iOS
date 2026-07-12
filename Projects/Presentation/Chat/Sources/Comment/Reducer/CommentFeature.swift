//
//  CommentFeature.swift
//  Chat
//
//

import Foundation

import CommentDomain
import CommentDomainInterface
import CommonDomainInterface
import ComposableArchitecture
import DomainInterface
import Entity
import BattleDomain
import BattleDomainInterface
import LogMacro
import PerspectiveDomain
import PerspectiveDomainInterface
import PickeDesignKit
import UseCase

@Reducer
public struct CommentFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var battleId: Int = 0
    public var perspectiveId: Int?
    /// 관점 등록 시 사용할 내 옵션(투표한 진영) optionId.
    public var myOptionId: Int?
    public var title: String = ""
    public var voteSummary: VoteSummary = .mock
    public var isLoadingStats: Bool = false
    public var isLoadingComments: Bool = false
    public var isSubmitting: Bool = false
    public var nextCursor: String?
    public var hasNext: Bool = false
    public var selectedFilter: CommentFilter = .all
    public var selectedSort: CommentSort = .popular
    public var reportTargetCommentID: UUID?
    /// "…" 메뉴(수정/삭제 또는 신고)를 띄울 대상 댓글 id.
    public var menuTargetCommentID: UUID?
    /// 수정 중인 관점 perspectiveId (입력창이 수정 모드).
    public var editingPerspectiveId: Int?
    /// 삭제 확인 알럿의 대상 perspectiveId.
    public var deleteTargetPerspectiveId: Int?
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?

    /// 메뉴 대상 댓글(있으면 confirmationDialog 표시).
    public var menuTargetComment: CommentItem? {
      guard let id = menuTargetCommentID else { return nil }
      return comments.first { $0.id == id }
    }

    public var comments: [CommentItem] = []
    public var commentText: String = ""

    public var filteredComments: [CommentItem] {
      switch selectedFilter {
      case .all:
        comments
      case .optionA:
        comments.filter { $0.option == .a }
      case .optionB:
        comments.filter { $0.option == .b }
      }
    }

    public var isSendEnabled: Bool {
      !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !isSubmitting
    }

    /// pre 투표 대비 post 투표에서 진영이 바뀌었는지.
    /// 사후투표 후엔 칩을 항상 노출하되, 이 값에 따라 문구만 분기한다.
    public var isMindChanged: Bool = false

    /// 생각 변화 칩 문구 — 바뀜/안 바뀜 양쪽 모두 노출.
    public var changeBadgeTitle: String {
      isMindChanged ? "생각이 바뀌었어요" : "생각이 바뀌지 않았어요"
    }

    public init(battleId: Int = 0, isMindChanged: Bool = false) {
      self.battleId = battleId
      self.isMindChanged = isMindChanged
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
    case forwardTapped
    case shareTapped
    case filterTapped(CommentFilter)
    case sortTapped(CommentSort)
    case reportPopupDismissed
    case menuDismissed
    case commentMenu(id: UUID, action: CommentMenuAction)
    case commentRow(id: UUID, action: CommentRowAction)
    case sendTapped
  }

  public enum CommentMenuAction: Equatable {
    case more
    case edit
    case delete
    case report
  }

  public enum CommentRowAction: Equatable {
    case openReply
    case reportConfirm
    case like
  }

  public enum AsyncAction: Equatable {
    case fetchBattle
    case fetchMyPerspective
    case fetchVoteStats
    case fetchPerspectives(reset: Bool)
    case toggleLike(commentId: Int, currentlyLiked: Bool)
    case createComment(content: String)
    case updatePerspective(perspectiveId: Int, content: String)
    case deletePerspective(perspectiveId: Int)
    case reportPerspective(perspectiveId: Int)
    case fetchPerspectiveLikes(perspectiveId: Int)
  }

  public enum InnerAction: Equatable {
    case battleResponse(Result<BattleDetail, BattleError>)
    case myPerspectiveResponse(Result<BattlePerspective?, BattleError>)
    case voteStatsResponse(Result<BattleVoteStats, BattleError>)
    case perspectivesResponse(Result<BattlePerspectivePage, BattleError>, reset: Bool)
    case likeResponse(Result<CommentLikeResult, CommentError>)
    case createCommentResponse(Result<BattlePerspective, BattleError>)
    case mutationFinished
    case perspectiveLikesResponse(Result<CommentLikeResult, CommentError>)
  }

  @CasePathable
  public enum ScopeAction: Equatable {
    case customAlert(PresentationAction<CustomAlertAction>)
  }

  public enum DelegateAction: Equatable {
    case dismiss
    case openReply(CommentItem)
    case openCuration(battleId: Int)
  }

  nonisolated enum CancelID: Hashable {
    case fetchBattle
    case fetchMyPerspective
    case fetchVoteStats
    case fetchPerspectives
    case toggleLike
    case createComment
  }

  @Dependency(\.battleUseCase) private var battleUseCase
  @Dependency(\.commentUseCase) private var commentUseCase
  @Dependency(\.perspectiveUseCase) private var perspectiveUseCase
  @Dependency(\.analyticsUseCase) private var analyticsUseCase

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding(\.commentText):
        if state.commentText.count > 200 {
          state.commentText = String(state.commentText.prefix(200))
        }
        return .none

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

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$customAlert, action: \.scope.customAlert) {
      CustomConfirmAlert()
    }
  }
}

extension CommentFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      analyticsUseCase.track(.screenView(screen: .comment, referrer: nil))
      return .merge(
        .send(.async(.fetchBattle)),
        .send(.async(.fetchMyPerspective)),
        .send(.async(.fetchVoteStats)),
        .send(.async(.fetchPerspectives(reset: true)))
      )

    case .backButtonTapped:
      return .send(.delegate(.dismiss))

    case .forwardTapped:
      // 앱바 우측 > : 큐레이팅(흥미 기반 추천 배틀) 화면으로 이동
      return .send(.delegate(.openCuration(battleId: state.battleId)))

    case .shareTapped:
      analyticsUseCase.track(.uiAction(action: .commentShare, screen: .comment))
      return .none

    case let .commentRow(id, action):
      switch action {
      case .openReply:
        guard let comment = state.comments.first(where: { $0.id == id }) else { return .none }
        state.reportTargetCommentID = nil
        return .send(.delegate(.openReply(comment)))
      case .reportConfirm:
        state.reportTargetCommentID = nil
        guard let comment = state.comments.first(where: { $0.id == id }),
              let pid = comment.perspectiveId
        else { return .none }
        return .send(.async(.reportPerspective(perspectiveId: pid)))
      case .like:
        guard let index = state.comments.firstIndex(where: { $0.id == id }),
              let commentId = state.comments[index].perspectiveId
        else { return .none }
        let wasLiked = state.comments[index].isLiked
        state.comments[index].isLiked.toggle()
        state.comments[index].likeCount += state.comments[index].isLiked ? 1 : -1
        return .send(.async(.toggleLike(commentId: commentId, currentlyLiked: wasLiked)))
      }

    case .menuDismissed:
      state.menuTargetCommentID = nil
      return .none

    case let .commentMenu(id, action):
      switch action {
      case .more:
        // "…" 탭 → 해당 댓글 바로 아래 메뉴 토글 (내 글: 수정/삭제, 남 글: 신고)
        state.menuTargetCommentID = (state.menuTargetCommentID == id) ? nil : id
      case .edit:
        state.menuTargetCommentID = nil
        guard let comment = state.comments.first(where: { $0.id == id }),
              let pid = comment.perspectiveId
        else { return .none }
        state.editingPerspectiveId = pid
        state.commentText = comment.content
      case .delete:
        state.menuTargetCommentID = nil
        guard let comment = state.comments.first(where: { $0.id == id }),
              let pid = comment.perspectiveId
        else { return .none }
        state.deleteTargetPerspectiveId = pid
        state.customAlert = .deletePerspective()
      case .report:
        state.menuTargetCommentID = nil
        state.reportTargetCommentID = id
        state.customAlert = .report()
      }
      return .none

    case .reportPopupDismissed:
      state.reportTargetCommentID = nil
      state.customAlert = nil
      return .none

    case let .filterTapped(filter):
      analyticsUseCase.track(.uiAction(action: .commentFilter, screen: .comment))
      state.selectedFilter = filter
      state.reportTargetCommentID = nil
      return .send(.async(.fetchPerspectives(reset: true)))

    case let .sortTapped(sort):
      analyticsUseCase.track(.uiAction(action: .commentSort, screen: .comment))
      state.selectedSort = sort
      state.reportTargetCommentID = nil
      return .send(.async(.fetchPerspectives(reset: true)))

    case .sendTapped:
      let text = state.commentText.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !text.isEmpty, !state.isSubmitting else { return .none }
      state.isSubmitting = true
      state.commentText = ""
      if let editId = state.editingPerspectiveId {
        state.editingPerspectiveId = nil
        return .send(.async(.updatePerspective(perspectiveId: editId, content: text)))
      }
      return .send(.async(.createComment(content: text)))
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
          state.customAlert = nil
          if let pid = state.deleteTargetPerspectiveId {
            state.deleteTargetPerspectiveId = nil
            return .send(.async(.deletePerspective(perspectiveId: pid)))
          }
          if let id = state.reportTargetCommentID {
            return .send(.view(.commentRow(id: id, action: .reportConfirm)))
          }
          return .none

        case .cancelTapped:
          state.reportTargetCommentID = nil
          state.deleteTargetPerspectiveId = nil
          state.customAlert = nil
          return .none
        }

      case .dismiss:
        state.reportTargetCommentID = nil
        state.deleteTargetPerspectiveId = nil
        state.customAlert = nil
        return .none
      }
    }
  }

  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetchBattle:
      let battleId = state.battleId
      return .run { [repository = battleUseCase] send in
        let result = await Result {
          try await repository.fetchBattle(battleId: battleId)
        }
        .mapError(BattleError.from)
        return await send(.inner(.battleResponse(result)))
      }
      .cancellable(id: CancelID.fetchBattle, cancelInFlight: true)

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

    case .fetchVoteStats:
      state.isLoadingStats = true
      let battleId = state.battleId
      return .run { [repository = battleUseCase] send in
        let result = await Result {
          try await repository.fetchVoteStats(battleId: battleId)
        }
        .mapError(BattleError.from)
        return await send(.inner(.voteStatsResponse(result)))
      }
      .cancellable(id: CancelID.fetchVoteStats, cancelInFlight: true)

    case let .fetchPerspectives(reset):
      state.isLoadingComments = true
      // 초기/정렬/필터/등록 후 reset 시 리스트를 비워 스켈레톤이 노출되도록 한다.
      if reset { state.comments = [] }
      let battleId = state.battleId
      let cursor = reset ? nil : state.nextCursor
      let optionId: Int? = {
        switch state.selectedFilter {
        case .all: return nil
        case .optionA: return state.voteSummary.optionA.optionId > 0 ? state.voteSummary.optionA.optionId : nil
        case .optionB: return state.voteSummary.optionB.optionId > 0 ? state.voteSummary.optionB.optionId : nil
        }
      }()
      let sort = state.selectedSort.perspectiveSort
      return .run { [repository = battleUseCase] send in
        let result = await Result {
          try await repository.fetchPerspectives(
            battleId: battleId,
            cursor: cursor,
            size: 20,
            optionId: optionId,
            sort: sort
          )
        }
        .mapError(BattleError.from)
        return await send(.inner(.perspectivesResponse(result, reset: reset)))
      }
      .cancellable(id: CancelID.fetchPerspectives, cancelInFlight: true)

    case let .toggleLike(commentId, currentlyLiked):
      // commentId 는 관점(perspective) id. 관점 좋아요는 perspectives/{id}/likes 사용.
      return .run { [repository = perspectiveUseCase] send in
        let result = await Result {
          if currentlyLiked {
            try await repository.unlikePerspective(perspectiveId: commentId)
          } else {
            try await repository.likePerspective(perspectiveId: commentId)
          }
        }
        .mapError(CommentError.from)
        return await send(.inner(.likeResponse(result)))
      }
      .cancellable(id: CancelID.toggleLike, cancelInFlight: false)

    case let .createComment(content):
      let battleId = state.battleId
      // 등록 진영: 현재 선택된 필터 탭의 옵션. 전체 탭이면 내 투표 진영(myOptionId).
      let optionId: Int? = {
        switch state.selectedFilter {
        case .all: return state.myOptionId
        case .optionA: return state.voteSummary.optionA.optionId > 0 ? state.voteSummary.optionA.optionId : state
          .myOptionId
        case .optionB: return state.voteSummary.optionB.optionId > 0 ? state.voteSummary.optionB.optionId : state
          .myOptionId
        }
      }()
      // 관점 등록: POST /battles/{id}/perspectives, body {content, optionId}
      return .run { [battle = battleUseCase, analyticsUseCase] send in
        let result = await Result {
          try await battle.createPerspective(battleId: battleId, content: content, optionId: optionId)
        }
        .mapError(BattleError.from)
        if case .success = result {
          analyticsUseCase.track(
            .communityAction(CommunityActionData(contentID: "\(battleId)", commentLength: content.count))
          )
        }
        return await send(.inner(.createCommentResponse(result)))
      }
      .cancellable(id: CancelID.createComment, cancelInFlight: false)

    case let .updatePerspective(perspectiveId, content):
      return .run { [repository = perspectiveUseCase] send in
        try? await repository.updatePerspective(perspectiveId: perspectiveId, content: content)
        await send(.inner(.mutationFinished))
      }

    case let .deletePerspective(perspectiveId):
      return .run { [repository = perspectiveUseCase] send in
        try? await repository.deletePerspective(perspectiveId: perspectiveId)
        await send(.inner(.mutationFinished))
      }

    case let .reportPerspective(perspectiveId):
      return .run { [repository = perspectiveUseCase] _ in
        try? await repository.reportPerspective(perspectiveId: perspectiveId)
      }

    case let .fetchPerspectiveLikes(perspectiveId):
      return .run { [repository = perspectiveUseCase] send in
        let result = await Result {
          try await repository.fetchPerspectiveLikes(perspectiveId: perspectiveId)
        }
        .mapError(CommentError.from)
        return await send(.inner(.perspectiveLikesResponse(result)))
      }
    }
  }

  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .battleResponse(result):
      switch result {
      case let .success(detail):
        state.title = detail.battleInfo.title
        // 필터 탭/아바타에 쓸 옵션 title·대표를 배틀 상세에서 채운다.
        // (vote-stats 가 비어 있어도 실제 A/B title 이 노출되도록)
        let options = detail.battleInfo.options
        if options.count >= 2 {
          state.voteSummary.optionA.optionId = options[0].optionId
          state.voteSummary.optionA.title = options[0].title
          state.voteSummary.optionA.representative = options[0].representative
          state.voteSummary.optionA.imageUrl = options[0].imageUrl
          state.voteSummary.optionB.optionId = options[1].optionId
          state.voteSummary.optionB.title = options[1].title
          state.voteSummary.optionB.representative = options[1].representative
          state.voteSummary.optionB.imageUrl = options[1].imageUrl
        }
        // 내 관점이 아직 없으면 투표 진영(userVoteStatus)으로 등록 optionId 결정.
        if state.myOptionId == nil, options.count >= 2 {
          switch detail.userVoteStatus {
          case .pro: state.myOptionId = options[0].optionId
          case .con: state.myOptionId = options[1].optionId
          default: break
          }
        }
      case let .failure(error):
        Log.error("[CommentFeature] fetchBattle failed: \(error.localizedDescription)")
      }
      return .none

    case let .myPerspectiveResponse(result):
      switch result {
      case let .success(perspective):
        state.perspectiveId = perspective?.perspectiveId
        if let optionId = perspective?.option.optionId { state.myOptionId = optionId }
        // 내 perspectiveId 가 늦게 로드돼도 기존 목록에서 내 글을 표시.
        if let myPid = perspective?.perspectiveId {
          for index in state.comments.indices where state.comments[index].perspectiveId == myPid {
            state.comments[index].isMine = true
          }
        }
      case let .failure(error):
        Log.error("[CommentFeature] fetchMyPerspective failed: \(error.localizedDescription)")
      }
      return .none

    case let .voteStatsResponse(result):
      state.isLoadingStats = false
      switch result {
      case let .success(stats):
        state.voteSummary = makeSummary(from: stats, fallback: state.voteSummary)
      case let .failure(error):
        Log.error("[CommentFeature] fetchVoteStats failed: \(error.localizedDescription)")
      }
      return .none

    case let .perspectivesResponse(result, reset):
      state.isLoadingComments = false
      switch result {
      case let .success(page):
        let myPid = state.perspectiveId
        // 진영(.a/.b) 은 옵션 label 문자열이 아니라 optionId 로 판별(서버 label 이 "A"/"B" 가 아닐 수 있음).
        let optionAId = state.voteSummary.optionA.optionId
        let mapped = page.items.enumerated().map { idx, item -> CommentItem in
          var comment = CommentItem(item: item, order: idx)
          if optionAId > 0 {
            comment.option = item.option.optionId == optionAId ? .a : .b
          }
          // 서버 isMyPerspective 가 누락/false 여도 내 perspectiveId 와 일치하면 내 글로 판정.
          if let myPid, comment.perspectiveId == myPid {
            comment.isMine = true
          }
          return comment
        }
        state.comments = reset ? mapped : state.comments + mapped
        state.nextCursor = page.nextCursor
        state.hasNext = page.hasNext
        // 좋아요 수/상태(likeCount·isLiked)는 목록 응답 값을 그대로 신뢰한다.
        // (이전엔 댓글마다 GET /perspectives/{id}/likes 로 덮어써 수치가 로드 후 바뀌는 문제가 있었음)
        return .none
      case let .failure(error):
        Log.error("[CommentFeature] fetchPerspectives failed: \(error.localizedDescription)")
      }
      return .none

    case let .likeResponse(result):
      switch result {
      case let .success(payload):
        if let index = state.comments.firstIndex(where: { $0.perspectiveId == payload.perspectiveId }) {
          state.comments[index].likeCount = payload.likeCount
          state.comments[index].isLiked = payload.isLiked
        }
      case let .failure(error):
        Log.error("[CommentFeature] toggleLike failed: \(error.localizedDescription)")
      }
      return .none

    case let .createCommentResponse(result):
      state.isSubmitting = false
      switch result {
      case let .success(perspective):
        // 서버는 댓글을 "유저가 투표한 진영"에 저장한다(요청 optionId 무시). 응답의 실제 진영
        // (perspective.option)으로 필터를 전환해 방금 쓴 댓글이 그 진영 탭에서 보이도록 한다.
        let votedOptionId = perspective.option.optionId
        state.myOptionId = votedOptionId
        if votedOptionId == state.voteSummary.optionA.optionId {
          state.selectedFilter = .optionA
        } else if votedOptionId == state.voteSummary.optionB.optionId {
          state.selectedFilter = .optionB
        }
        return .send(.async(.fetchPerspectives(reset: true)))
      case let .failure(error):
        Log.error("[CommentFeature] createComment failed: \(error.localizedDescription)")
        return .none
      }

    case .mutationFinished:
      // 관점 수정/삭제 완료 → 입력 상태 복구 + 목록 갱신
      state.isSubmitting = false
      return .send(.async(.fetchPerspectives(reset: true)))

    case let .perspectiveLikesResponse(result):
      if case let .success(payload) = result,
         let index = state.comments.firstIndex(where: { $0.perspectiveId == payload.perspectiveId })
      {
        // GET 은 좋아요 "수" 조회 용도. isLiked 는 목록 응답 값을 신뢰하고 덮어쓰지 않는다.
        state.comments[index].likeCount = payload.likeCount
      }
      return .none
    }
  }

  /// API 응답(BattleVoteStats) 을 화면 모델 VoteSummary 로 매핑.
  /// 옵션이 2개 이상이라 가정 — 부족하거나 매핑 실패 시 fallback 유지.
  private func makeSummary(
    from stats: BattleVoteStats,
    fallback: VoteSummary
  ) -> VoteSummary {
    guard stats.options.count >= 2 else { return fallback }
    let optionA = matchedStatsOption(
      in: stats.options,
      fallbackOptionId: fallback.optionA.optionId,
      fallbackIndex: 0
    )
    let optionB = matchedStatsOption(
      in: stats.options,
      fallbackOptionId: fallback.optionB.optionId,
      fallbackIndex: 1
    )
    return VoteSummary(
      changeBadgeTitle: fallback.changeBadgeTitle,
      optionA: makeOptionSummary(optionA, fallback: fallback.optionA),
      optionB: makeOptionSummary(optionB, fallback: fallback.optionB)
    )
  }

  private func matchedStatsOption(
    in options: [BattleVoteStatsOption],
    fallbackOptionId: Int,
    fallbackIndex: Int
  ) -> BattleVoteStatsOption {
    if fallbackOptionId > 0,
       let matched = options.first(where: { $0.optionId == fallbackOptionId })
    {
      return matched
    }
    return options[fallbackIndex]
  }

  private func makeOptionSummary(
    _ option: BattleVoteStatsOption,
    fallback: VoteOptionSummary
  ) -> VoteOptionSummary {
    VoteOptionSummary(
      // vote-stats 응답 순서가 배틀 상세와 달라도 fallback optionId 로 A/B 진영을 유지한다.
      optionId: option.optionId > 0 ? option.optionId : fallback.optionId,
      label: option.label ?? fallback.label,
      title: option.title.isEmpty ? fallback.title : option.title,
      representative: fallback.representative,
      imageUrl: option.imageUrl ?? fallback.imageUrl,
      percentage: option.ratio
    )
  }
}
