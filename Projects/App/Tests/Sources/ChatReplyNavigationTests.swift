//
//  ChatReplyNavigationTests.swift
//  PickeTests
//
//  Created by Picke on 10/19/26.
//

import CommentDomainInterface
import ComposableArchitecture
import TCAFlow
import Testing

@testable import Picke

@MainActor
struct ChatReplyNavigationTests {
  @Test
  func 클래스_댓글에서_답글을_열고_뒤로가면_댓글로_돌아온다() async {
    let parent = CommentItem(
      perspectiveId: 42,
      author: "작성자",
      timeAgo: "방금 전",
      option: .a,
      content: "부모 의견",
      replyCount: 1,
      likeCount: 0,
      createdOrder: 0
    )
    let store = TestStore(initialState: ChatCoordinator.State(commentBattleId: 7)) {
      ChatCoordinator()
    }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(
      id: 0,
      action: .comment(.delegate(.openReply(parent)))
    )))
    #expect(store.state.routes.count == 2)
    guard case let .commentReply(reply)? = store.state.routes.last?.screen else {
      Issue.record("답글 화면으로 push되지 않음")
      return
    }
    #expect(reply.perspectiveId == 42)

    await store.send(.router(.routeAction(
      id: 1,
      action: .commentReply(.delegate(.dismiss))
    )))
    await store.receive {
      guard case .view(.backAction) = $0 else { return false }
      return true
    }
    #expect(store.state.routes.count == 1)
    guard case .comment = store.state.routes.last?.screen else {
      Issue.record("댓글 화면으로 돌아오지 않음")
      return
    }
  }
}
