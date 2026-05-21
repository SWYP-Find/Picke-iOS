//
//  ChatCoordinatorView.swift
//  Chat
//

import Foundation

import SwiftUI

import ComposableArchitecture
import TCAFlow

public struct ChatCoordinatorView: View {
  @Bindable private var store: StoreOf<ChatCoordinator>

  public init(store: StoreOf<ChatCoordinator>) {
    self.store = store
  }

  public var body: some View {
    TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
      case let .preVote(preVoteStore):
        PreVoteView(store: preVoteStore)
          .toolbar(.hidden, for: .tabBar)
      case let .chatRoom(chatRoomStore):
        ChatRoomView(store: chatRoomStore)
          .toolbar(.hidden, for: .tabBar)
      case let .comment(commentStore):
        CommentView(store: commentStore)
          .toolbar(.hidden, for: .tabBar)
      }
    }
  }
}
