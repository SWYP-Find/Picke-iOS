//
//  LoginFeature.swift
//  Auth
//
//  Created by Wonji Suh  on 5/11/26.
//

import Foundation
import ComposableArchitecture

@Reducer
public struct LoginFeature {
  public init() {}
  
  @ObservableState
  public struct State: Equatable {
    
    public init() {
      
    }
  }
  
  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case delegate(DelegateAction)
  }
  
  
  // MARK: - ViewAction
  @CasePathable
  public enum View {
  }
  
  // MARK: - AsyncAction 비동기 처리 액션
  
  public enum AsyncAction: Equatable {
    
  }
  
  // MARK: - 앱내에서 사용하는 액션
  
  public enum InnerAction: Equatable {
    
  }
  
  // MARK: - NavigationAction
  
  public enum DelegateAction: Equatable {
    
  }
  
  nonisolated enum CancelID: Hashable {
    
  }
  
  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding(_):
        return .none
        
      case .view(let viewAction):
        return handleViewAction(state: &state, action: viewAction)
        
      case .async(let asyncAction):
        return handleAsyncAction(state: &state, action: asyncAction)
        
      case .inner(let innerAction):
        return handleInnerAction(state: &state, action: innerAction)
        
      case .delegate(let delegateAction):
        return handleDelegateAction(state: &state, action: delegateAction)
        
        
      }
    }
    
  }
}

extension LoginFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
      
    }
  }
  
  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {}
  }
  
  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    
  }
  
  private func handleDelegateAction(
    state: inout State,
    action: DelegateAction
  ) -> Effect<Action> {
    switch action {
      
    }
  }
}
