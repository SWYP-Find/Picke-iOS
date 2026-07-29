//
//  ProfileCoordinator.swift
//  Profile
//

import Foundation

import ComposableArchitecture
import TCAFlow

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
    /// 딥링크(알림) → 포인트 내역 진입.
    case openPointHistory
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

    // 포인트 내역에서 주제 제안 → 배틀 만들기 화면 진입.
    case .routeAction(_, action: .pointHistory(.delegate(.suggestTopic))):
      state.routes.push(.battleProposal(.init()))
      return .none

    // 배틀 만들기 닫기(취소/제안 완료) → 뒤로.
    case .routeAction(_, action: .battleProposal(.delegate(.dismiss))):
      return .send(.view(.backAction))

    // 포인트 내역 상단 백탭 → 뒤로.
    case .routeAction(_, action: .pointHistory(.delegate(.dismiss))):
      return .send(.view(.backAction))

    // 나의 철학자 유형 카드 탭 → 리캡 화면 진입.
    case .routeAction(_, action: .profile(.delegate(.openPhilosopher))):
      state.routes.push(.recap(.init()))
      return .none

    // 리캡 백탭 → 뒤로.
    case .routeAction(_, action: .recap(.delegate(.dismiss))):
      return .send(.view(.backAction))

    // 설정 아이콘 → 설정 화면 진입.
    case let .routeAction(_, action: .profile(.delegate(.openSettings(nickname)))):
      state.routes.push(.settings(.init(nickname: nickname)))
      return .none

    // 설정 상단 백탭 → 뒤로.
    case .routeAction(_, action: .settings(.delegate(.dismiss))):
      return .send(.view(.backAction))

    // 알림 설정 → 알림 설정 화면.
    case .routeAction(_, action: .settings(.delegate(.openNotificationSettings))):
      state.routes.push(.notificationSetting(.init()))
      return .none

    // 알림 설정 백탭 → 뒤로.
    case .routeAction(_, action: .notificationSetting(.delegate(.dismiss))):
      return .send(.view(.backAction))

    // 회원 탈퇴 → 탈퇴 사유 화면 진입.
    case let .routeAction(_, action: .settings(.delegate(.openWithdraw(nickname)))):
      state.routes.push(.withdraw(.init(nickname: nickname)))
      return .none

    // 탈퇴 사유 "픽케로 다시 돌아가기" → 뒤로.
    case .routeAction(_, action: .withdraw(.delegate(.dismiss))):
      return .send(.view(.backAction))

    // 메뉴 선택 — 화면 진입 분기.
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

    // 내 배틀 기록 백탭 → 뒤로.
    case .routeAction(_, action: .battleRecord(.delegate(.dismiss))):
      return .send(.view(.backAction))

    // 내 콘텐츠 활동 백탭 → 뒤로.
    case .routeAction(_, action: .contentActivity(.delegate(.dismiss))):
      return .send(.view(.backAction))

    // 공지사항·이벤트 백탭 → 뒤로.
    case .routeAction(_, action: .notice(.delegate(.dismiss))):
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
    case .openPointHistory:
      // 중복 스택 방지 후 포인트 내역 진입.
      state.routes.goBackToRoot()
      state.routes.push(.pointHistory(.init()))
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
    case contentActivity(ContentActivityFeature)
    case notice(NoticeFeature)
    case notificationSetting(NotificationSettingFeature)
    case withdraw(WithdrawReasonFeature)
    case battleProposal(BattleProposalFeature)
    case recap(RecapFeature)
  }
}

// swiftformat:enable extensionAccessControl

extension ProfileCoordinator.ProfileScreen.State: Equatable {}
