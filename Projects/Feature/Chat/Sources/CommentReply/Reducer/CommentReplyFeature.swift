//
//  CommentReplyFeature.swift
//  Chat
//

//

import Foundation
import PickeCoreLogger

import CommentDomainInterface
import BattleDomainInterface
import ComposableArchitecture
import PerspectiveDomainInterface
import PickeDesignKit
import PickeSharedUI
import PickeAnalyticsInterface

@Reducer
public struct CommentReplyFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var perspectiveId: Int
    public var parentComment: CommentItem
    /// 딥링크(알림)로 진입 시 스크롤할 답글 commentId.
    public var targetCommentId: Int?
    public var replies: [CommentReplyItem] = []
    public var replyText: String = ""
    public var isLoadingDetail: Bool = false
    public var isLoadingReplies: Bool = false
    public var nextCursor: String?
    public var hasNext: Bool = false
    public var editingCommentId: Int?
    /// "…" 메뉴를 띄울 대상 답글 id.
    public var menuTargetReplyId: UUID?
    /// 부모(관점) "…" 메뉴 열림.
    public var parentMenuOpen: Bool = false
    /// 입력창이 부모 관점 수정 모드.
    public var editingParent: Bool = false
    /// 삭제 확인 알럿 대상 commentId.
    public var deleteTargetCommentId: Int?
    /// 신고 확인 알럿 대상 commentId.
    public var reportTargetCommentId: Int?
    /// 삭제/신고 알럿이 부모(관점) 대상.
    public var deleteParentPending: Bool = false
    public var reportParentPending: Bool = false
    @Presents public var customAlert: CustomAlertState<CustomAlertAction>?

    public var menuTargetReply: CommentReplyItem? {
      guard let id = menuTargetReplyId else { return nil }
      return replies.first { $0.id == id }
    }

    public var isSendEnabled: Bool {
      !replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public init(
      perspectiveId: Int,
      parentComment: CommentItem
    ) {
      self.perspectiveId = perspectiveId
      self.parentComment = parentComment
    }

    /// 딥링크(알림) 단독 진입 — 부모 관점은 onAppear 의 fetchParent 로 채운다.
    /// commentId 가 있으면 답글 로드 후 해당 답글로 스크롤.
    public init(perspectiveId: Int, targetCommentId: Int? = nil) {
      self.perspectiveId = perspectiveId
      self.targetCommentId = targetCommentId
      parentComment = CommentItem(
        perspectiveId: perspectiveId,
        author: "",
        timeAgo: "",
        option: .a,
        content: "",
        replyCount: 0,
        likeCount: 0,
        createdOrder: 0
      )
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
    case parentLikeTapped
    case replyLikeTapped(UUID)
    case sendTapped
    case beginEditing(commentId: Int, content: String)
    case cancelEditing
    case deleteTapped(commentId: Int)
    case menuDismissed
    case replyMenu(id: UUID, action: MenuAction)
    case parentMenu(MenuAction)
  }

  public enum MenuAction: Equatable {
    case more
    case edit
    case delete
    case report
  }

  @CasePathable
  public enum ScopeAction: Equatable {
    case customAlert(PresentationAction<CustomAlertAction>)
  }

  public enum AsyncAction: Equatable {
    case fetchParent
    case fetchReplies(reset: Bool)
    case createReply(content: String)
    case updateReply(commentId: Int, content: String)
    case deleteReply(commentId: Int)
    case toggleParentLike(currentlyLiked: Bool)
    case toggleReplyLike(commentId: Int, currentlyLiked: Bool)
    case fetchParentLikes
    case reportComment(commentId: Int)
    case updateParent(content: String)
    case deleteParent
    case reportParent
  }

  public enum InnerAction: Equatable {
    case parentResponse(Result<BattlePerspective, PerspectiveError>)
    case repliesResponse(Result<PerspectiveCommentPage, CommentError>, reset: Bool)
    case createResponse(Result<PerspectiveCommentMutationResult, CommentError>)
    case updateResponse(Result<PerspectiveCommentMutationResult, CommentError>, commentId: Int)
    case deleteResponse(Result<Int, CommentError>)
    case parentLikeResponse(Result<CommentLikeResult, CommentError>)
    case replyLikeResponse(Result<CommentLikeResult, CommentError>)
    case parentLikesResponse(Result<CommentLikeResult, CommentError>)
  }

  public enum DelegateAction: Equatable {
    case dismiss
  }

  nonisolated enum CancelID: Hashable {
    case fetchParent
    case fetchReplies
    case mutate
    case like
  }

  @Dependency(\.perspectiveUseCase) private var perspectiveUseCase
  @Dependency(\.commentUseCase) private var commentUseCase
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

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$customAlert, action: \.scope.customAlert) {
      CustomConfirmAlert()
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
          if state.deleteParentPending {
            state.deleteParentPending = false
            return .send(.async(.deleteParent))
          }
          if state.reportParentPending {
            state.reportParentPending = false
            return .send(.async(.reportParent))
          }
          if let commentId = state.deleteTargetCommentId {
            state.deleteTargetCommentId = nil
            return .send(.async(.deleteReply(commentId: commentId)))
          }
          if let commentId = state.reportTargetCommentId {
            state.reportTargetCommentId = nil
            return .send(.async(.reportComment(commentId: commentId)))
          }
          return .none
        case .cancelTapped:
          state.deleteTargetCommentId = nil
          state.reportTargetCommentId = nil
          state.deleteParentPending = false
          state.reportParentPending = false
          state.customAlert = nil
          return .none
        }
      case .dismiss:
        state.deleteTargetCommentId = nil
        state.reportTargetCommentId = nil
        state.deleteParentPending = false
        state.reportParentPending = false
        state.customAlert = nil
        return .none
      }
    }
  }
}

// MARK: - View handler

extension CommentReplyFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .onAppear:
      return .merge(
        .send(.async(.fetchParent)),
        .send(.async(.fetchParentLikes)),
        .send(.async(.fetchReplies(reset: true)))
      )

    case .backButtonTapped:
      return .send(.delegate(.dismiss))

    case .parentLikeTapped:
      analyticsUseCase.track(.uiAction(action: .commentLike, screen: .commentReply))
      let wasLiked = state.parentComment.isLiked
      state.parentComment.isLiked.toggle()
      state.parentComment.likeCount += state.parentComment.isLiked ? 1 : -1
      return .send(.async(.toggleParentLike(currentlyLiked: wasLiked)))

    case let .replyLikeTapped(id):
      analyticsUseCase.track(.uiAction(action: .commentLike, screen: .commentReply))
      guard let index = state.replies.firstIndex(where: { $0.id == id }),
            let commentId = state.replies[index].commentId
      else { return .none }
      let wasLiked = state.replies[index].isLiked
      state.replies[index].isLiked.toggle()
      state.replies[index].likeCount += state.replies[index].isLiked ? 1 : -1
      return .send(.async(.toggleReplyLike(commentId: commentId, currentlyLiked: wasLiked)))

    case .sendTapped:
      let text = state.replyText.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !text.isEmpty else { return .none }
      state.replyText = ""
      if state.editingParent {
        state.editingParent = false
        return .send(.async(.updateParent(content: text)))
      }
      if let editingId = state.editingCommentId {
        state.editingCommentId = nil
        return .send(.async(.updateReply(commentId: editingId, content: text)))
      }
      return .send(.async(.createReply(content: text)))

    case let .beginEditing(commentId, content):
      state.editingCommentId = commentId
      state.replyText = content
      return .none

    case .cancelEditing:
      state.editingCommentId = nil
      state.replyText = ""
      return .none

    case let .deleteTapped(commentId):
      return .send(.async(.deleteReply(commentId: commentId)))

    case .menuDismissed:
      state.menuTargetReplyId = nil
      return .none

    case let .replyMenu(id, action):
      switch action {
      case .more:
        state.menuTargetReplyId = (state.menuTargetReplyId == id) ? nil : id
        return .none
      case .edit:
        state.menuTargetReplyId = nil
        guard let reply = state.replies.first(where: { $0.id == id }),
              let commentId = reply.commentId
        else { return .none }
        state.editingCommentId = commentId
        state.replyText = reply.content
        return .none
      case .delete:
        state.menuTargetReplyId = nil
        guard let reply = state.replies.first(where: { $0.id == id }),
              let commentId = reply.commentId
        else { return .none }
        state.deleteTargetCommentId = commentId
        state.customAlert = .deleteComment()
        return .none
      case .report:
        state.menuTargetReplyId = nil
        guard let reply = state.replies.first(where: { $0.id == id }),
              let commentId = reply.commentId
        else { return .none }
        state.reportTargetCommentId = commentId
        state.customAlert = .report()
        return .none
      }

    case let .parentMenu(action):
      switch action {
      case .more:
        state.parentMenuOpen.toggle()
      case .edit:
        state.parentMenuOpen = false
        state.editingCommentId = nil
        state.editingParent = true
        state.replyText = state.parentComment.content
      case .delete:
        state.parentMenuOpen = false
        state.deleteParentPending = true
        state.customAlert = .deletePerspective()
      case .report:
        state.parentMenuOpen = false
        state.reportParentPending = true
        state.customAlert = .report()
      }
      return .none
    }
  }
}

// MARK: - Async handler

extension CommentReplyFeature {
  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetchParent:
      state.isLoadingDetail = true
      let pid = state.perspectiveId
      return .run { [repository = perspectiveUseCase] send in
        let result = await Result {
          try await repository.fetchPerspective(perspectiveId: pid)
        }
        .mapError(PerspectiveError.from)
        return await send(.inner(.parentResponse(result)))
      }
      .cancellable(id: CancelID.fetchParent, cancelInFlight: true)

    case let .fetchReplies(reset):
      state.isLoadingReplies = true
      // 갱신(reset) 시 리스트를 비워 스켈레톤이 노출되도록 한다.
      if reset { state.replies = [] }
      let pid = state.perspectiveId
      let cursor = reset ? nil : state.nextCursor
      return .run { [repository = perspectiveUseCase] send in
        let result = await Result {
          try await repository.fetchLabeledComments(perspectiveId: pid, cursor: cursor, size: 20)
        }
        .mapError(CommentError.from)
        return await send(.inner(.repliesResponse(result, reset: reset)))
      }
      .cancellable(id: CancelID.fetchReplies, cancelInFlight: true)

    case let .createReply(content):
      let pid = state.perspectiveId
      return .run { [repository = perspectiveUseCase] send in
        let result = await Result {
          try await repository.createComment(perspectiveId: pid, content: content)
        }
        .mapError(CommentError.from)
        return await send(.inner(.createResponse(result)))
      }
      .cancellable(id: CancelID.mutate, cancelInFlight: false)

    case let .updateReply(commentId, content):
      let pid = state.perspectiveId
      return .run { [repository = perspectiveUseCase] send in
        let result = await Result {
          try await repository.updateComment(perspectiveId: pid, commentId: commentId, content: content)
        }
        .mapError(CommentError.from)
        return await send(.inner(.updateResponse(result, commentId: commentId)))
      }
      .cancellable(id: CancelID.mutate, cancelInFlight: false)

    case let .deleteReply(commentId):
      let pid = state.perspectiveId
      return .run { [repository = perspectiveUseCase] send in
        let result = await Result {
          try await repository.deleteComment(perspectiveId: pid, commentId: commentId)
          return commentId
        }
        .mapError(CommentError.from)
        return await send(.inner(.deleteResponse(result)))
      }
      .cancellable(id: CancelID.mutate, cancelInFlight: false)

    case let .toggleParentLike(currentlyLiked):
      // 부모는 관점(perspective) → perspectives/{id}/likes 사용.
      let perspectiveId = state.perspectiveId
      return .run { [repository = perspectiveUseCase] send in
        let result = await Result {
          if currentlyLiked {
            try await repository.unlikePerspective(perspectiveId: perspectiveId)
          } else {
            try await repository.likePerspective(perspectiveId: perspectiveId)
          }
        }
        .mapError(CommentError.from)
        return await send(.inner(.parentLikeResponse(result)))
      }
      .cancellable(id: CancelID.like, cancelInFlight: false)

    case let .toggleReplyLike(commentId, currentlyLiked):
      return .run { [repository = commentUseCase] send in
        let result = await Result {
          if currentlyLiked {
            try await repository.unlikeComment(commentId: commentId)
          } else {
            try await repository.likeComment(commentId: commentId)
          }
        }
        .mapError(CommentError.from)
        return await send(.inner(.replyLikeResponse(result)))
      }
      .cancellable(id: CancelID.like, cancelInFlight: false)

    case .fetchParentLikes:
      let perspectiveId = state.perspectiveId
      return .run { [repository = perspectiveUseCase] send in
        let result = await Result {
          try await repository.fetchPerspectiveLikes(perspectiveId: perspectiveId)
        }
        .mapError(CommentError.from)
        return await send(.inner(.parentLikesResponse(result)))
      }

    case let .reportComment(commentId):
      let perspectiveId = state.perspectiveId
      return .run { [repository = perspectiveUseCase] _ in
        try? await repository.reportComment(perspectiveId: perspectiveId, commentId: commentId)
      }

    case let .updateParent(content):
      let perspectiveId = state.perspectiveId
      return .run { [repository = perspectiveUseCase] send in
        try? await repository.updatePerspective(perspectiveId: perspectiveId, content: content)
        await send(.async(.fetchParent))
      }

    case .deleteParent:
      let perspectiveId = state.perspectiveId
      return .run { [repository = perspectiveUseCase] send in
        try? await repository.deletePerspective(perspectiveId: perspectiveId)
        await send(.delegate(.dismiss))
      }

    case .reportParent:
      let perspectiveId = state.perspectiveId
      return .run { [repository = perspectiveUseCase] _ in
        try? await repository.reportPerspective(perspectiveId: perspectiveId)
      }
    }
  }
}

// MARK: - Inner handler

extension CommentReplyFeature {
  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case let .parentResponse(result):
      state.isLoadingDetail = false
      switch result {
      case let .success(perspective):
        state.parentComment = CommentItem(item: perspective, order: 0)
      case let .failure(error):
        PickeLogger.error("[CommentReplyFeature] fetchParent failed: \(error.localizedDescription)", category: .ui)
      }
      return .none

    case let .repliesResponse(result, reset):
      state.isLoadingReplies = false
      switch result {
      case let .success(page):
        let mapped = page.items.enumerated().map { idx, item in
          CommentReplyItem(item: item, parentOption: state.parentComment.option, order: idx)
        }
        state.replies = reset ? mapped : state.replies + mapped
        state.nextCursor = page.nextCursor
        state.hasNext = page.hasNext
      case let .failure(error):
        PickeLogger.error("[CommentReplyFeature] fetchReplies failed: \(error.localizedDescription)", category: .ui)
      }
      return .none

    case let .createResponse(result):
      switch result {
      case .success:
        return .send(.async(.fetchReplies(reset: true)))
      case let .failure(error):
        PickeLogger.error("[CommentReplyFeature] createReply failed: \(error.localizedDescription)", category: .ui)
        return .none
      }

    case let .updateResponse(result, _):
      switch result {
      case .success:
        // 수정 후 리스트 reset 갱신 → 스켈레톤 노출
        return .send(.async(.fetchReplies(reset: true)))
      case let .failure(error):
        PickeLogger.error("[CommentReplyFeature] updateReply failed: \(error.localizedDescription)", category: .ui)
        return .none
      }

    case let .deleteResponse(result):
      switch result {
      case let .success(commentId):
        state.replies.removeAll { $0.commentId == commentId }
        if state.parentComment.replyCount > 0 { state.parentComment.replyCount -= 1 }
      case let .failure(error):
        PickeLogger.error("[CommentReplyFeature] deleteReply failed: \(error.localizedDescription)", category: .ui)
      }
      return .none

    case let .parentLikeResponse(result):
      switch result {
      case let .success(payload):
        state.parentComment.likeCount = payload.likeCount
        state.parentComment.isLiked = payload.isLiked
      case let .failure(error):
        PickeLogger.error("[CommentReplyFeature] toggleParentLike failed: \(error.localizedDescription)", category: .ui)
      }
      return .none

    case let .replyLikeResponse(result):
      switch result {
      case let .success(payload):
        if let index = state.replies.firstIndex(where: { $0.commentId == payload.perspectiveId }) {
          state.replies[index].likeCount = payload.likeCount
          state.replies[index].isLiked = payload.isLiked
        }
      case let .failure(error):
        PickeLogger.error("[CommentReplyFeature] toggleReplyLike failed: \(error.localizedDescription)", category: .ui)
      }
      return .none

    case let .parentLikesResponse(result):
      switch result {
      case let .success(payload):
        state.parentComment.likeCount = payload.likeCount
      case let .failure(error):
        PickeLogger.error("[CommentReplyFeature] fetchParentLikes failed: \(error.localizedDescription)", category: .ui)
      }
      return .none
    }
  }
}
