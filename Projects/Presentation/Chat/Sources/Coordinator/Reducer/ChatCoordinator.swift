//
//  ChatCoordinator.swift
//  Chat
//
//  채팅방 모듈 진입점. battleId 를 받아 PreVote → ChatRoom 흐름을 자체적으로 라우팅한다.
//  향후 사후 투표 결과 / 공유 등 후속 화면이 필요해지면 ChatScreen enum 에 case 만 추가.
//

import Foundation

import ComposableArchitecture
import LogMacro
import TCAFlow

@FlowCoordinator(screen: "ChatScreen", navigation: true)
public struct ChatCoordinator {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var routes: [Route<ChatScreen.State>]

    public init(battleId: Int = 0) {
      routes = [.root(.preVote(.init(battleId: battleId)), embedInNavigationView: true)]
    }

    /// 딥링크(알림) 단독 진입 — 관점(답글) 화면으로 바로 시작.
    public init(perspectiveId: Int, commentId: Int? = nil) {
      routes = [.root(
        .commentReply(.init(perspectiveId: perspectiveId, targetCommentId: commentId)),
        embedInNavigationView: true
      )]
    }
  }

  @CasePathable
  public enum Action {
    case router(IndexedRouterActionOf<ChatScreen>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case navigation(NavigationAction)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case backAction
    case backToRootAction
  }

  public enum AsyncAction: Equatable {}
  public enum InnerAction: Equatable {}
  public enum NavigationAction: Equatable {}

  public enum DelegateAction: Equatable {
    case dismiss
    /// 큐레이팅 X — 채팅 디투어 전체를 빠져나가 부모 스택 최상위(root)로 복귀.
    case popToRoot
  }

  func handleRoute(
    state: inout State,
    action: Action
  ) -> Effect<Action> {
    switch action {
    case let .router(routeAction):
      routerAction(state: &state, action: routeAction)
    case let .view(viewAction):
      handleViewAction(state: &state, action: viewAction)
    case .async, .inner, .navigation:
      .none
    case let .delegate(delegateAction):
      handleDelegateAction(state: &state, action: delegateAction)
    }
  }
}

extension ChatCoordinator {
  private func routerAction(
    state: inout State,
    action: IndexedRouterActionOf<ChatScreen>
  ) -> Effect<Action> {
    switch action {
    case .routeAction(_, action: .preVote(.delegate(.dismiss))):
      return .send(.delegate(.dismiss))

    case let .routeAction(_, action: .preVote(.delegate(.voteSubmitted(battleId, voteMode, _, isMindChanged)))):
      switch voteMode {
      case .pre:
        state.routes.push(.chatRoom(.init(battleId: battleId)))
      case .post:
        state.routes.push(.comment(.init(battleId: battleId, isMindChanged: isMindChanged)))
      }
      return .none

    case let .routeAction(_, action: .preVote(.delegate(.alreadyFinalVoted(battleId)))):
      state.routes.push(.comment(.init(battleId: battleId)))
      return .none

    case .routeAction(_, action: .chatRoom(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case let .routeAction(_, action: .chatRoom(.delegate(.requestFinalVote(battleId)))):
      state.routes.push(.preVote(.init(battleId: battleId, voteMode: .post)))
      return .none

    case .routeAction(_, action: .comment(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case let .routeAction(_, action: .comment(.delegate(.openReply(comment)))):
      // perspectiveId 가 없는 관점은 대댓글 식별이 불가능하므로 진입하지 않는다.
      guard let perspectiveId = comment.perspectiveId else {
        Log.error("[ChatCoordinator] openReply 무시 — perspectiveId 가 nil 인 CommentItem")
        return .none
      }
      state.routes.push(
        .commentReply(
          .init(
            perspectiveId: perspectiveId,
            parentComment: comment
          )
        )
      )
      return .none

    case .routeAction(_, action: .commentReply(.delegate(.dismiss))):
      // 단독(루트) 진입이면 코디네이터 자체를 닫고, 스택 내부면 뒤로.
      return state.routes.count <= 1 ? .send(.delegate(.dismiss)) : .send(.view(.backAction))

    case let .routeAction(_, action: .comment(.delegate(.openCuration(battleId)))):
      state.routes.push(.curation(.init(battleId: battleId)))
      return .none

    case .routeAction(_, action: .curation(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case .routeAction(_, action: .curation(.delegate(.close))):
      // X : 채팅 디투어 전체를 빠져나가 부모 스택 최상위(root)로 복귀
      return .send(.delegate(.popToRoot))

    case let .routeAction(_, action: .curation(.delegate(.openBattle(battleId)))):
      state.routes.push(.preVote(.init(battleId: battleId)))
      return .none

    default:
      return .none
    }
  }

  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backAction:
      state.routes.goBack()
      return .none
    case .backToRootAction:
      state.routes.goBackToRoot()
      return .none
    }
  }

  private func handleDelegateAction(
    state _: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
    case .dismiss, .popToRoot:
      .none
    }
  }
}

// swiftformat:disable extensionAccessControl
extension ChatCoordinator {
  @Reducer
  public enum ChatScreen {
    case preVote(PreVoteFeature)
    case chatRoom(ChatRoomFeature)
    case comment(CommentFeature)
    case commentReply(CommentReplyFeature)
    case curation(CurationFeature)
  }
}

// swiftformat:enable extensionAccessControl

extension ChatCoordinator.ChatScreen.State: Equatable {}
