//
//  ProfileCoordinator.swift
//  Profile
//
//  마이 탭 코디네이터. 루트는 ProfileFeature, 편집/세부 화면은 추후 push.
//

import Foundation

import ComposableArchitecture
import Entity
import TCAFlow
import Web

@FlowCoordinator(screen: "ProfileScreen", navigation: true)
public struct ProfileCoordinator {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var routes: [Route<ProfileScreen.State>]

    public init() {
      routes = [.root(.profile(.init()), embedInNavigationView: true)]
    }
  }

  @CasePathable
  public enum Action {
    case router(IndexedRouterActionOf<ProfileScreen>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case navigation(NavigationAction)
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
    }
  }
}

extension ProfileCoordinator {
  private func routerAction(
    state: inout State,
    action: IndexedRouterActionOf<ProfileScreen>
  ) -> Effect<Action> {
    switch action {
    // 프로필 편집 / 포인트 충전 / 철학자 / 메뉴 — 세부 화면 추가 시 분기 확장.
    case .routeAction(_, action: .profile(.delegate(.editProfile))):
      return .none

    // 포인트(크레딧) 충전 영역 탭 → 포인트 내역 화면 진입.
    case .routeAction(_, action: .profile(.delegate(.chargePoint))):
      state.routes.push(.pointHistory(.init()))
      return .none

    // 포인트 내역 상단 백탭 → 뒤로.
    case .routeAction(_, action: .pointHistory(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case .routeAction(_, action: .profile(.delegate(.openPhilosopher))):
      return .none

    case .routeAction(_, action: .profile(.delegate(.openNotification))):
      return .none

    // 설정 아이콘 → 설정 화면 진입.
    case .routeAction(_, action: .profile(.delegate(.openSettings))):
      state.routes.push(.settings(.init()))
      return .none

    // 설정 상단 백탭 → 뒤로.
    case .routeAction(_, action: .settings(.delegate(.dismiss))):
      return .send(.view(.backAction))

    // 개인정보 처리방침 → 웹뷰.
    case .routeAction(_, action: .settings(.delegate(.openPrivacy))):
      state.routes.push(.web(.init(url: TermsDocument.privacy.urlString)))
      return .none

    // 서비스 약관 → 웹뷰.
    case .routeAction(_, action: .settings(.delegate(.openTerms))):
      state.routes.push(.web(.init(url: TermsDocument.service.urlString)))
      return .none

    // 웹뷰 뒤로.
    case .routeAction(_, action: .web(.backToRoot)):
      return .send(.view(.backAction))

    // 메뉴 선택 — 내 배틀 기록만 화면 진입 (나머지는 추후).
    case let .routeAction(_, action: .profile(.delegate(.menuSelected(item)))):
      switch item {
      case .battleHistory:
        state.routes.push(.battleRecord(.init()))
      case .contentActivity, .noticeEvent:
        break
      }
      return .none

    // 내 배틀 기록 백탭 → 뒤로.
    case .routeAction(_, action: .battleRecord(.delegate(.dismiss))):
      return .send(.view(.backAction))

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
}

// swiftformat:disable extensionAccessControl
extension ProfileCoordinator {
  @Reducer
  public enum ProfileScreen {
    case profile(ProfileFeature)
    case pointHistory(PointHistoryFeature)
    case settings(SettingsFeature)
    case battleRecord(BattleRecordFeature)
    case web(WebReducer)
  }
}

// swiftformat:enable extensionAccessControl

extension ProfileCoordinator.ProfileScreen.State: Equatable {}
