//
//  ChatCoordinator.swift
//  Chat
//

import Foundation

import ChatInterface
import CommentDomainInterface
import ComposableArchitecture
import DomainInterface
import LogMacro
import PickeDesignKit
import Shared
import TCAFlow

@FlowCoordinator(screen: "ChatScreen", navigation: true)
public struct ChatCoordinator {
  public init() {}

  @Dependency(\.audioPlayer) private var audioPlayer

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

    /// 이미 참여 완료한 배틀 — 관점(댓글) 화면으로 바로 시작.
    public init(commentBattleId: Int) {
      routes = [.root(
        .comment(.init(battleId: commentBattleId)),
        embedInNavigationView: true
      )]
    }

    public init(route: ChatRoute) {
      switch route {
      case let .preVote(battleId):
        self.init(battleId: battleId)
      case let .perspective(perspectiveId, commentId):
        self.init(perspectiveId: perspectiveId, commentId: commentId)
      case let .comment(battleId):
        self.init(commentBattleId: battleId)
      }
    }
  }

  @CasePathable
  public enum Action {
    case router(IndexedRouterActionOf<ChatScreen>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case navigation(NavigationAction)
    case delegate(ChatDelegate)
  }

  @CasePathable
  public enum View {
    case backAction
    case backToRootAction
  }

  public enum AsyncAction: Equatable {}
  public enum InnerAction: Equatable {}
  public enum NavigationAction: Equatable {}

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
      // 사전투표 루트에서 감지된 재진입이면 사전투표 화면을 남기지 않고 관점 화면으로 교체.
      // (스택 중간 — 최종투표 중복 500 — 이면 기존처럼 push)
      if state.routes.count <= 1 {
        state.routes = [.root(.comment(.init(battleId: battleId)), embedInNavigationView: true)]
      } else {
        state.routes.push(.comment(.init(battleId: battleId)))
      }
      return .none

    case .routeAction(_, action: .chatRoom(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case let .routeAction(_, action: .chatRoom(.delegate(.requestFinalVote(battleId)))):
      // QA-38: 투표 안정화 전까지 진입 차단. 플래그가 켜지면 기존 흐름 그대로 동작.
      guard FeatureFlag.isVotingEnabled else {
        return .run { _ in
          await MainActor.run {
            ToastManager.shared.showInfo(FeatureFlag.votingDisabledMessage)
          }
        }
      }
      state.routes.push(.preVote(.init(battleId: battleId, voteMode: .post)))
      return .none

    case .routeAction(_, action: .comment(.delegate(.dismiss))):
      // 단독(루트) 진입이면 코디네이터 자체를 닫고, 스택 내부면 뒤로.
      return state.routes.count <= 1 ? .send(.delegate(.dismiss)) : .send(.view(.backAction))

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
      // QA-38: 투표 안정화 전까지 진입 차단. 플래그가 켜지면 기존 흐름 그대로 동작.
      guard FeatureFlag.isVotingEnabled else {
        return .run { _ in
          await MainActor.run {
            ToastManager.shared.showInfo(FeatureFlag.votingDisabledMessage)
          }
        }
      }
      state.routes.push(.preVote(.init(battleId: battleId)))
      return .none

    case let .updateRoutes(newRoutes):
      // 스와이프 뒤로가기 등으로 chatRoom 이 스택에서 사라지면 오디오를 정지한다.
      // 버튼 뒤로가기는 chatRoom(.delegate(.dismiss)) 경로에서 이미 pause 되지만,
      // 인터랙티브 pop 은 ChatRoom 의 onDisappear 이펙트가 teardown 시 취소되어 음성이 계속 나므로
      // 코디네이터 레벨에서 확실히 정지시킨다. (idle player 의 pause 는 no-op 이라 안전)
      let hasChatRoom = newRoutes.contains { route in
        if case .chatRoom = route.screen { return true }
        return false
      }
      if !hasChatRoom {
        return .run { [player = audioPlayer] _ in await player.pause() }
      }
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
    action: ChatDelegate
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
