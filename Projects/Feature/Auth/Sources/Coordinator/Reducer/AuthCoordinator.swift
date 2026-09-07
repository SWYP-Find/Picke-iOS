//
//  AuthCoordinator.swift
//  Auth
//
//  Created by Wonji Suh  on 5/11/26.
//

import Foundation

import AuthInterface
import ComposableArchitecture
import TCAFlow

import AuthDomainInterface

@FlowCoordinator(screen: "AuthScreen", navigation: true)
public struct AuthCoordinator {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    var routes: [Route<AuthScreen.State>]

    public init() {
      @Shared(.userSession) var userSession: UserSession
      routes = [.root(.login(.init(userSession: userSession)), embedInNavigationView: true)]
    }

    public init(route: AuthRoute) {
      switch route {
      case .login:
        self.init()
      }
    }
  }

  @CasePathable
  public enum Action {
    case router(IndexedRouterActionOf<AuthScreen>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(AuthDelegate)
  }

  // MARK: - ViewAction

  @CasePathable
  public enum View {
    case backAction
    case backToRootAction
  }

  // MARK: - AsyncAction 비동기 처리 액션

  public enum AsyncAction: Equatable {}

  // MARK: - 앱내에서 사용하는 액션

  public enum InnerAction: Equatable {}

  func handleRoute(
    state: inout State,
    action: Action
  ) -> Effect<Action> {
    switch action {
    case let .router(routeAction):
      routerAction(state: &state, action: routeAction)

    case let .view(viewAction):
      handleViewAction(state: &state, action: viewAction)

    case let .async(asyncAction):
      handleAsyncAction(state: &state, action: asyncAction)

    case let .inner(innerAction):
      handleInnerAction(state: &state, action: innerAction)

    case let .delegate(delegateAction):
      handleDelegateAction(state: &state, action: delegateAction)
    }
  }
}

// MARK: - Effect Cancellation IDs

nonisolated enum AuthCancelID: Hashable {
  case loginEffects
}

extension AuthCoordinator {
  private func routerAction(
    state: inout State,
    action: IndexedRouterActionOf<AuthScreen>
  ) -> Effect<Action> {
    switch action {
    // MARK: - 로그인 성공 → 온보딩 화면 푸시

    case .routeAction(_, action: .login(.delegate(.presentOnboarding))):
      state.routes.push(.onboarding(.init()))
      return .none

    // MARK: - 온보딩 완료 → 루트로 (다음 플로우 연결 지점)

    case .routeAction(id: _, action: .login(.delegate(.presentMainTab))):
      return .send(.delegate(.presentMainTab))

    case .routeAction(_, action: .onboarding(.delegate(.presentMainTab))):
      return .send(.delegate(.presentMainTab))

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
    action: AuthDelegate
  ) -> Effect<Action> {
    switch action {
    case .presentMainTab:
      return .none
    }
  }

  private func handleAsyncAction(
    state _: inout State,
    action _: AsyncAction
  ) -> Effect<Action> {
    .none
  }

  private func handleInnerAction(
    state _: inout State,
    action _: InnerAction
  ) -> Effect<Action> {
    .none
  }
}

// swiftformat:disable extensionAccessControl
extension AuthCoordinator {
  @Reducer
  public enum AuthScreen {
    case login(LoginFeature)
    case onboarding(OnBoardingFeature)
  }
}

// swiftformat:enable extensionAccessControl

extension AuthCoordinator.AuthScreen.State: Equatable {}
