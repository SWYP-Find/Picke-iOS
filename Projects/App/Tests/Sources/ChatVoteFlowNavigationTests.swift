//
//  ChatVoteFlowNavigationTests.swift
//  PickeTests
//
//  Created by Picke on 11/11/26.
//

import BattleDomainInterface
import ComposableArchitecture
import TCAFlow
import Testing

@testable import Picke

/// Android `BattleNavGraph` 의 popUpTo 흐름과 맞춘 Chat 스택.
@MainActor
struct ChatVoteFlowNavigationTests {
  @Test
  func 투표_흐름은_이전_화면을_스택에_남기지_않는다() async {
    let store = TestStore(initialState: ChatCoordinator.State(route: .preVote(battleId: 7))) {
      ChatCoordinator()
    }
    store.exhaustivity = .off
    let result = PreVoteResult(voteId: 1, status: .created)

    // 사전투표 → 청취: 사전투표 자리를 바꾼다.
    await store.send(.router(.routeAction(
      id: 0,
      action: .preVote(.delegate(.voteSubmitted(battleId: 7, voteMode: .pre, result: result, isMindChanged: false)))
    )))
    #expect(store.state.routes.count == 1)
    guard case .chatRoom = store.state.routes.first?.screen else {
      Issue.record("청취 화면으로 바뀌지 않음")
      return
    }

    // 청취 → 최종투표: 청취 자리를 바꾼다.
    await store.send(.router(.routeAction(
      id: 0,
      action: .chatRoom(.delegate(.requestFinalVote(battleId: 7)))
    )))
    #expect(store.state.routes.count == 1)
    guard case let .preVote(post)? = store.state.routes.first?.screen else {
      Issue.record("최종투표 화면으로 바뀌지 않음")
      return
    }
    #expect(post.voteMode == .post)

    // 최종투표 → 관점: 관점 화면만 남는다.
    await store.send(.router(.routeAction(
      id: 0,
      action: .preVote(.delegate(.voteSubmitted(battleId: 7, voteMode: .post, result: result, isMindChanged: true)))
    )))
    #expect(store.state.routes.count == 1)
    guard case let .comment(comment)? = store.state.routes.first?.screen else {
      Issue.record("관점 화면으로 바뀌지 않음")
      return
    }
    #expect(comment.isMindChanged)
  }

  @Test
  func 루트가_된_청취_화면에서_뒤로가면_흐름을_닫는다() async {
    var state = ChatCoordinator.State(route: .preVote(battleId: 7))
    state.routes[screenAt: 0] = .chatRoom(.init(battleId: 7))
    let store = TestStore(initialState: state) { ChatCoordinator() }
    store.exhaustivity = .off

    await store.send(.router(.routeAction(id: 0, action: .chatRoom(.delegate(.dismiss)))))
    await store.receive(\.delegate, .dismiss)
  }
}
