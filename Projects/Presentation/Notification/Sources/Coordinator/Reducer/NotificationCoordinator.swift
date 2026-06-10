//
//  NotificationCoordinator.swift
//  Notification
//
//  알림 모듈 진입점. 루트는 알림받기 목록(NotificationFeature).
//  상세 화면 연결 시 NotificationScreen 에 case 추가.
//

import Foundation

import ComposableArchitecture
import TCAFlow

@FlowCoordinator(screen: "NotificationScreen", navigation: true)
public struct NotificationCoordinator {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var routes: [Route<NotificationScreen.State>]

    public init() {
      routes = [.root(.notification(.init()), embedInNavigationView: true)]
    }
  }

  @CasePathable
  public enum Action {
    case router(IndexedRouterActionOf<NotificationScreen>)
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
    /// 알림 모듈 전체를 빠져나가 부모 스택으로 복귀.
    case dismiss
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

extension NotificationCoordinator {
  private func routerAction(
    state _: inout State,
    action: IndexedRouterActionOf<NotificationScreen>
  ) -> Effect<Action> {
    switch action {
    // 목록(루트) 백탭 → 알림 모듈 종료(부모로 복귀).
    case .routeAction(_, action: .notification(.delegate(.dismiss))):
      return .send(.delegate(.dismiss))

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
    case .dismiss:
      return .none
    }
  }
}

// swiftformat:disable extensionAccessControl
extension NotificationCoordinator {
  @Reducer
  public enum NotificationScreen {
    case notification(NotificationFeature)
  }
}

// swiftformat:enable extensionAccessControl

extension NotificationCoordinator.NotificationScreen.State: Equatable {}
