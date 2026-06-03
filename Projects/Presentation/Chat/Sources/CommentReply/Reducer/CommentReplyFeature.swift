//
//  CommentReplyFeature.swift
//  Chat
//
//  대댓글 화면.
//  - GET    /api/v1/perspectives/{pid}                       (부모 댓글 상세)
//  - GET    /api/v1/perspectives/{pid}/comments/labeled      (답글 페이지)
//  - POST   /api/v1/perspectives/{pid}/comments              (답글 작성)
//  - PUT    /api/v1/perspectives/{pid}/comments/{cid}        (답글 수정)
//  - DELETE /api/v1/perspectives/{pid}/comments/{cid}        (답글 삭제)
//  - POST/DELETE /api/v1/comments/{cid}/likes                (좋아요 토글)
//

import Foundation

import ComposableArchitecture
import DomainInterface
import Entity
import LogMacro
import UseCase
import DesignSystem

@Reducer
public struct CommentReplyFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var perspectiveId: Int
    public var parentComment: CommentItem
    public var replies: [CommentReplyItem] = []
    public var replyText: String = ""
    public var isLoadingDetail: Bool = false
    public var isLoadingReplies: Bool = false
    public var nextCursor: String?
    public var hasNext: Bool = false
    public var editingCommentId: Int?
    /// "…" 메뉴를 띄울 대상 답글 id.
    public var menuTargetReplyId: UUID?
    /// 삭제 확인 알럿 대상 commentId.
    public var deleteTargetCommentId: Int?
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
    case replyMoreTapped(UUID)
    case menuDismissed
    case replyEditTapped(UUID)
    case replyDeleteTapped(UUID)
    case replyReportTapped(UUID)
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

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding(\.replyText):
        if state.replyText.count > 200 {
          state.replyText = String(state.replyText.prefix(200))
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
          guard let commentId = state.deleteTargetCommentId else { return .none }
          state.deleteTargetCommentId = nil
          return .send(.async(.deleteReply(commentId: commentId)))
        case .cancelTapped:
          state.deleteTargetCommentId = nil
          state.customAlert = nil
          return .none
        }
      case .dismiss:
        state.deleteTargetCommentId = nil
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
      let wasLiked = state.parentComment.isLiked
      state.parentComment.isLiked.toggle()
      state.parentComment.likeCount += state.parentComment.isLiked ? 1 : -1
      return .send(.async(.toggleParentLike(currentlyLiked: wasLiked)))

    case let .replyLikeTapped(id):
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

    case let .replyMoreTapped(id):
      state.menuTargetReplyId = id
      return .none

    case .menuDismissed:
      state.menuTargetReplyId = nil
      return .none

    case let .replyEditTapped(id):
      state.menuTargetReplyId = nil
      guard let reply = state.replies.first(where: { $0.id == id }),
            let commentId = reply.commentId
      else { return .none }
      state.editingCommentId = commentId
      state.replyText = reply.content
      return .none

    case let .replyDeleteTapped(id):
      state.menuTargetReplyId = nil
      guard let reply = state.replies.first(where: { $0.id == id }),
            let commentId = reply.commentId
      else { return .none }
      state.deleteTargetCommentId = commentId
      state.customAlert = .deleteComment()
      return .none

    case let .replyReportTapped(id):
      state.menuTargetReplyId = nil
      Log.debug("[CommentReplyFeature] report reply tapped: \(id)")
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
        Log.error("[CommentReplyFeature] fetchParent failed: \(error.localizedDescription)")
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
        Log.error("[CommentReplyFeature] fetchReplies failed: \(error.localizedDescription)")
      }
      return .none

    case let .createResponse(result):
      switch result {
      case .success:
        return .send(.async(.fetchReplies(reset: true)))
      case let .failure(error):
        Log.error("[CommentReplyFeature] createReply failed: \(error.localizedDescription)")
        return .none
      }

    case let .updateResponse(result, _):
      switch result {
      case let .success(payload):
        if let index = state.replies.firstIndex(where: { $0.commentId == payload.commentId }) {
          state.replies[index].content = payload.content
        }
      case let .failure(error):
        Log.error("[CommentReplyFeature] updateReply failed: \(error.localizedDescription)")
      }
      return .none

    case let .deleteResponse(result):
      switch result {
      case let .success(commentId):
        state.replies.removeAll { $0.commentId == commentId }
        if state.parentComment.replyCount > 0 { state.parentComment.replyCount -= 1 }
      case let .failure(error):
        Log.error("[CommentReplyFeature] deleteReply failed: \(error.localizedDescription)")
      }
      return .none

    case let .parentLikeResponse(result):
      switch result {
      case let .success(payload):
        state.parentComment.likeCount = payload.likeCount
        state.parentComment.isLiked = payload.isLiked
      case let .failure(error):
        Log.error("[CommentReplyFeature] toggleParentLike failed: \(error.localizedDescription)")
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
        Log.error("[CommentReplyFeature] toggleReplyLike failed: \(error.localizedDescription)")
      }
      return .none

    case let .parentLikesResponse(result):
      switch result {
      case let .success(payload):
        state.parentComment.likeCount = payload.likeCount
      case let .failure(error):
        Log.error("[CommentReplyFeature] fetchParentLikes failed: \(error.localizedDescription)")
      }
      return .none
    }
  }
}
