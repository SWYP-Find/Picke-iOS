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
  }

  public enum AsyncAction: Equatable {
    case fetchParent
    case fetchReplies(reset: Bool)
    case createReply(content: String)
    case updateReply(commentId: Int, content: String)
    case deleteReply(commentId: Int)
    case toggleParentLike(currentlyLiked: Bool)
    case toggleReplyLike(commentId: Int, currentlyLiked: Bool)
  }

  public enum InnerAction: Equatable {
    case parentResponse(Result<BattlePerspective, CommentError>)
    case repliesResponse(Result<PerspectiveCommentPage, CommentError>, reset: Bool)
    case createResponse(Result<PerspectiveCommentMutationResult, CommentError>)
    case updateResponse(Result<PerspectiveCommentMutationResult, CommentError>, commentId: Int)
    case deleteResponse(Result<Int, CommentError>)
    case parentLikeResponse(Result<CommentLikeResult, CommentError>)
    case replyLikeResponse(Result<CommentLikeResult, CommentError>)
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

  @Dependency(\.perspectiveRepository) private var perspectiveRepository
  @Dependency(\.commentRepository) private var commentRepository

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

      case .delegate:
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
      return .run { [repository = perspectiveRepository] send in
        let result = await Result {
          try await repository.fetchPerspective(perspectiveId: pid)
        }
        .mapError(CommentError.from)
        return await send(.inner(.parentResponse(result)))
      }
      .cancellable(id: CancelID.fetchParent, cancelInFlight: true)

    case let .fetchReplies(reset):
      state.isLoadingReplies = true
      let pid = state.perspectiveId
      let cursor = reset ? nil : state.nextCursor
      return .run { [repository = perspectiveRepository] send in
        let result = await Result {
          try await repository.fetchLabeledComments(perspectiveId: pid, cursor: cursor, size: 20)
        }
        .mapError(CommentError.from)
        return await send(.inner(.repliesResponse(result, reset: reset)))
      }
      .cancellable(id: CancelID.fetchReplies, cancelInFlight: true)

    case let .createReply(content):
      let pid = state.perspectiveId
      return .run { [repository = perspectiveRepository] send in
        let result = await Result {
          try await repository.createComment(perspectiveId: pid, content: content)
        }
        .mapError(CommentError.from)
        return await send(.inner(.createResponse(result)))
      }
      .cancellable(id: CancelID.mutate, cancelInFlight: false)

    case let .updateReply(commentId, content):
      let pid = state.perspectiveId
      return .run { [repository = perspectiveRepository] send in
        let result = await Result {
          try await repository.updateComment(perspectiveId: pid, commentId: commentId, content: content)
        }
        .mapError(CommentError.from)
        return await send(.inner(.updateResponse(result, commentId: commentId)))
      }
      .cancellable(id: CancelID.mutate, cancelInFlight: false)

    case let .deleteReply(commentId):
      let pid = state.perspectiveId
      return .run { [repository = perspectiveRepository] send in
        let result = await Result {
          try await repository.deleteComment(perspectiveId: pid, commentId: commentId)
          return commentId
        }
        .mapError(CommentError.from)
        return await send(.inner(.deleteResponse(result)))
      }
      .cancellable(id: CancelID.mutate, cancelInFlight: false)

    case let .toggleParentLike(currentlyLiked):
      let commentId = state.perspectiveId
      return .run { [repository = commentRepository] send in
        let result = await Result {
          if currentlyLiked {
            try await repository.unlikeComment(commentId: commentId)
          } else {
            try await repository.likeComment(commentId: commentId)
          }
        }
        .mapError(CommentError.from)
        return await send(.inner(.parentLikeResponse(result)))
      }
      .cancellable(id: CancelID.like, cancelInFlight: false)

    case let .toggleReplyLike(commentId, currentlyLiked):
      return .run { [repository = commentRepository] send in
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
    }
  }
}
