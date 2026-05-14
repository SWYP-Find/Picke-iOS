//
//  AuthCoordinator.swift
//  Auth
//
//  Created by Wonji Suh  on 5/11/26.
//

import Foundation

import ComposableArchitecture
import TCAFlow

import Entity

@FlowCoordinator(screen: "AuthScreen", navigation: true)
public struct AuthCoordinator {
  public init() {}
  
  @ObservableState
  public struct State: Equatable {
    var routes: [Route<AuthScreen.State>]
    
    public init() {
      @Shared(.inMemory("UserSession")) var userSession: UserSession = .empty
      self.routes = [.root(.login(.init(userSession: userSession)), embedInNavigationView: true)]
    }
  }
  
  @CasePathable
  public enum Action {
    case router(IndexedRouterActionOf<AuthScreen>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case navigation(NavigationAction)
  }
  
  // MARK: - ViewAction
  
  @CasePathable
  public enum View {
    case backAction
    case backToRootAction
  }
  
  // MARK: - AsyncAction 비동기 처리 액션
  
  public enum AsyncAction: Equatable {
    
  }
  
  // MARK: - 앱내에서 사용하는 액션
  
  public enum InnerAction: Equatable {
    
  }
  
  // MARK: - NavigationAction
  
  public enum NavigationAction: Equatable {
    
  }
  
  func handleRoute(state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .router(let routeAction):
      return routerAction(state: &state, action: routeAction)
      
    case .view(let viewAction):
      return handleViewAction(state: &state, action: viewAction)
      
    case .async(let asyncAction):
      return handleAsyncAction(state: &state, action: asyncAction)
      
    case .inner(let innerAction):
      return handleInnerAction(state: &state, action: innerAction)
      
    case .navigation(let navigationAction):
      return handleNavigationAction(state: &state, action: navigationAction)
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
      
      // MARK: - 초대코드 입력
      
      
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
  
  private func handleNavigationAction(
    state: inout State,
    action: NavigationAction
  ) -> Effect<Action> {
    switch action {
  
      
   
    }
  }
  
  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    return .none
  }
  
  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    return .none
  }
}

extension AuthCoordinator {
  @Reducer
  public enum AuthScreen {
    case login(LoginFeature)
  }
}

extension AuthCoordinator.AuthScreen.State: Equatable {}
