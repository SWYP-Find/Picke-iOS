//
//  NoticeFeature.swift
//  Profile
//
//  공지사항 · 이벤트 — 탭 전환(공지사항/이벤트). API 미구현으로 빈 콘텐츠.
//

import Foundation

import ComposableArchitecture
import Entity

@Reducer
public struct NoticeFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var selectedTab: NoticeTab = .notice

    public init() {}
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case delegate(DelegateAction)
  }

  @CasePathable
  public enum View {
    case backTapped
    case tabSelected(NoticeTab)
  }

  public enum DelegateAction: Equatable {
    case dismiss
  }

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none

      case let .view(viewAction):
        return handleViewAction(state: &state, action: viewAction)

      case let .delegate(delegateAction):
        return handleDelegateAction(state: &state, action: delegateAction)
      }
    }
  }
}

extension NoticeFeature {
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backTapped:
      return .send(.delegate(.dismiss))

    case let .tabSelected(tab):
      state.selectedTab = tab
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
