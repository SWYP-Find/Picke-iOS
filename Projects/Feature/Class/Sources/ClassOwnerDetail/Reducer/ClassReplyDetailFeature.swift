//
//  ClassReplyDetailFeature.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture

@Reducer
public struct ClassReplyDetailFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public enum ViewState: Equatable {
      case unavailable
      case empty
      case loaded([Reply])
    }

    public let room: ClassRoom
    public let opinion: ClassOwnerOpinion?
    public let replies: [Reply]

    public struct Reply: Equatable, Identifiable, Sendable {
      public let id: Int
      public let author: String
      public let body: String
      public let date: String

      public init(
        id: Int,
        author: String,
        body: String,
        date: String
      ) {
        self.id = id
        self.author = author
        self.body = body
        self.date = date
      }
    }

    public init(
      room: ClassRoom,
      opinion: ClassOwnerOpinion? = nil,
      replies: [Reply] = []
    ) {
      self.room = room
      self.opinion = opinion
      self.replies = replies
    }

    public var viewState: ViewState {
      guard replies.isEmpty else { return .loaded(replies) }
      return opinion?.replyCount == 0 ? .empty : .unavailable
    }
  }

  public enum Action: ViewAction {
    case view(View)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View: Equatable {
    case backTapped
  }

  @CasePathable
  public enum DelegateAction: Equatable {
    case dismiss
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)
      case .delegate:
        return .none
      }
    }
  }
}

// MARK: - Action Handlers

extension ClassReplyDetailFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backTapped:
      return .send(.delegate(.dismiss))
    }
  }
}
