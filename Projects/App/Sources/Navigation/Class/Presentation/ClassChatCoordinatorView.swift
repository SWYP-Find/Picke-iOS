//
//  ClassChatCoordinatorView.swift
//  Picke
//
//  Created by Picke on 10/11/26.
//

import ComposableArchitecture
import DomainAssembly
import FeatureAssembly
import PickeDesignKit
import PickeSharedUI
import SwiftUI
import TCAFlow

struct ClassChatCoordinatorView: View {
  @Bindable private var store: StoreOf<ChatCoordinator>
  private let roomsByBattleID: [Int: ClassRoom]
  private let onOpenReport: (Int) -> Void

  init(
    store: StoreOf<ChatCoordinator>,
    roomsByBattleID: [Int: ClassRoom],
    onOpenReport: @escaping (Int) -> Void
  ) {
    self.store = store
    self.roomsByBattleID = roomsByBattleID
    self.onOpenReport = onOpenReport
  }

  var body: some View {
    TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
      Group {
        switch screen.case {
        case let .preVote(voteStore):
          if let room = roomsByBattleID[voteStore.battleId] {
            ClassVoteView(store: voteStore, room: room)
          } else {
            missingClassView
          }
        case let .chatRoom(chatStore):
          ChatRoomView(store: chatStore)
        case let .comment(commentStore):
          if roomsByBattleID[commentStore.battleId] != nil {
            ClassCommentView(store: commentStore, onOpenReport: onOpenReport)
          } else {
            missingClassView
          }
        case let .commentReply(replyStore):
          CommentReplyView(store: replyStore)
        case let .curation(curationStore):
          CurationView(store: curationStore)
        }
      }
      .toolbar(.hidden, for: .tabBar)
      .swipeBackButtonHidden()
    }
  }
}

private extension ClassChatCoordinatorView {
  var missingClassView: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { store.send(.delegate(.dismiss)) })
      PickeRetryErrorView(
        message: "클래스 정보를 불러오지 못했어요",
        retryTitle: "뒤로가기"
      ) {
        store.send(.delegate(.dismiss))
      }
    }
    .screenBackground()
  }
}
