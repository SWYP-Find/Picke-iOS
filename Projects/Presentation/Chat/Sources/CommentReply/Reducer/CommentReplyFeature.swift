//
//  CommentReplyFeature.swift
//  Chat
//

import Foundation

import ComposableArchitecture
import Entity

@Reducer
public struct CommentReplyFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var parentComment: CommentItem
    public var replies: [CommentReplyItem]
    public var replyText: String = ""

    public var isSendEnabled: Bool {
      !replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public init(
      parentComment: CommentItem,
      replies: [CommentReplyItem]? = nil
    ) {
      self.parentComment = parentComment
      self.replies = replies ?? CommentReplyItem.mocks(for: parentComment.option)
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case backButtonTapped
    case parentLikeTapped
    case replyLikeTapped(UUID)
    case sendTapped
  }

  public enum DelegateAction: Equatable {
    case dismiss
  }

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

      case .delegate:
        return .none
      }
    }
  }
}

extension CommentReplyFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backButtonTapped:
      return .send(.delegate(.dismiss))

    case .parentLikeTapped:
      state.parentComment.isLiked.toggle()
      state.parentComment.likeCount += state.parentComment.isLiked ? 1 : -1
      return .none

    case let .replyLikeTapped(id):
      guard let index = state.replies.firstIndex(where: { $0.id == id }) else { return .none }
      state.replies[index].isLiked.toggle()
      state.replies[index].likeCount += state.replies[index].isLiked ? 1 : -1
      return .none

    case .sendTapped:
      let text = state.replyText.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !text.isEmpty else { return .none }
      state.replies.insert(
        CommentReplyItem(
          author: "나",
          timeAgo: "방금 전",
          option: state.parentComment.option,
          content: text,
          likeCount: 0,
          createdOrder: (state.replies.map(\.createdOrder).max() ?? 0) + 1
        ),
        at: 0
      )
      state.parentComment.replyCount += 1
      state.replyText = ""
      return .none
    }
  }
}
