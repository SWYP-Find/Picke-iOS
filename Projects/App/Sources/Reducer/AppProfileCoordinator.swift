//
//  AppProfileCoordinator.swift
//  Picke
//
//  App 레이어의 마이페이지 조립 코디네이터.
//  Profile feature 와 Notification/Web feature 를 앱 조립 레이어에서 연결한다.
//

import Foundation

import ComposableArchitecture
import Entity
import Presentation
import TCAFlow

@FlowCoordinator(screen: "AppProfileScreen", navigation: true)
public struct AppProfileCoordinator {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var routes: [Route<AppProfileScreen.State>]

    public init() {
      routes = [.root(.profile(.init()), embedInNavigationView: true)]
    }
  }

  @CasePathable
  public enum Action {
    case router(IndexedRouterActionOf<AppProfileScreen>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case navigation(NavigationAction)
  }

  @CasePathable
  public enum View {
    case backAction
    case backToRootAction
    case openPointHistory
    case openTerms
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

private extension AppProfileCoordinator {
  func routerAction(
    state: inout State,
    action: IndexedRouterActionOf<AppProfileScreen>
  ) -> Effect<Action> {
    switch action {
    case .routeAction(_, action: .profile(.delegate(.editProfile))):
      return .none

    case .routeAction(_, action: .profile(.delegate(.chargePoint))):
      state.routes.push(.pointHistory(.init()))
      return .none

    case .routeAction(_, action: .pointHistory(.delegate(.suggestTopic))):
      state.routes.push(.battleProposal(.init()))
      return .none

    case .routeAction(_, action: .battleProposal(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case .routeAction(_, action: .pointHistory(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case .routeAction(_, action: .profile(.delegate(.openPhilosopher))):
      state.routes.push(.recap(.init()))
      return .none

    case .routeAction(_, action: .recap(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case let .routeAction(_, action: .profile(.delegate(.openSettings(nickname)))):
      state.routes.push(.settings(.init(nickname: nickname)))
      return .none

    case .routeAction(_, action: .profile(.delegate(.openNotification))):
      state.routes.push(.notification(.init(route: .inbox)))
      return .none

    case .routeAction(_, action: .notification(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case .routeAction(_, action: .settings(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case .routeAction(_, action: .settings(.delegate(.openNotificationSettings))):
      state.routes.push(.notificationSetting(.init()))
      return .none

    case .routeAction(_, action: .notificationSetting(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case .routeAction(_, action: .settings(.delegate(.openPrivacy))):
      state.routes.push(.web(.init(route: .init(url: TermsDocument.privacy.urlString))))
      return .none

    case .routeAction(_, action: .settings(.delegate(.openTerms))):
      state.routes.push(.web(.init(route: .init(url: TermsDocument.service.urlString))))
      return .none

    case let .routeAction(_, action: .settings(.delegate(.openWithdraw(nickname)))):
      state.routes.push(.withdraw(.init(nickname: nickname)))
      return .none

    case .routeAction(_, action: .withdraw(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case .routeAction(_, action: .web(.backToRoot)):
      return .send(.view(.backAction))

    case let .routeAction(_, action: .profile(.delegate(.menuSelected(item)))):
      switch item {
      case .battleHistory:
        state.routes.push(.battleRecord(.init()))
      case .contentActivity:
        state.routes.push(.contentActivity(.init()))
      case .noticeEvent:
        state.routes.push(.notice(.init()))
      }
      return .none

    case .routeAction(_, action: .battleRecord(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case .routeAction(_, action: .contentActivity(.delegate(.dismiss))):
      return .send(.view(.backAction))

    case .routeAction(_, action: .notice(.delegate(.dismiss))):
      return .send(.view(.backAction))

    default:
      return .none
    }
  }

  func handleViewAction(
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

    case .openPointHistory:
      state.routes.goBackToRoot()
      state.routes.push(.pointHistory(.init()))
      return .none

    case .openTerms:
      state.routes.goBackToRoot()
      state.routes.push(.web(.init(route: .init(url: TermsDocument.service.urlString))))
      return .none
    }
  }
}

// swiftformat:disable extensionAccessControl
extension AppProfileCoordinator {
  @Reducer
  public enum AppProfileScreen {
    case profile(ProfileFeature)
    case pointHistory(PointHistoryFeature)
    case settings(SettingsFeature)
    case battleRecord(BattleRecordFeature)
    case contentActivity(ContentActivityFeature)
    case notice(NoticeFeature)
    case notificationSetting(NotificationSettingFeature)
    case withdraw(WithdrawReasonFeature)
    case battleProposal(BattleProposalFeature)
    case recap(RecapFeature)
    case notification(NotificationCoordinator)
    case web(WebReducer)
  }
}

// swiftformat:enable extensionAccessControl

extension AppProfileCoordinator.AppProfileScreen.State: Equatable {}
