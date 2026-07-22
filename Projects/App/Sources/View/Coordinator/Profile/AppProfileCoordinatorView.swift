//
//  AppProfileCoordinatorView.swift
//  Picke
//
//  App 레이어의 마이페이지 조립 화면.
//

import SwiftUI

import ComposableArchitecture
import Presentation
import TCAFlow

public struct AppProfileCoordinatorView: View {
  @Bindable private var store: StoreOf<AppProfileCoordinator>

  public init(store: StoreOf<AppProfileCoordinator>) {
    self.store = store
  }

  public var body: some View {
    TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
      case let .profile(profileStore):
        ProfileView(store: profileStore)
      case let .pointHistory(pointHistoryStore):
        PointHistoryView(store: pointHistoryStore)
      case let .settings(settingsStore):
        SettingsView(store: settingsStore)
      case let .battleRecord(battleRecordStore):
        BattleRecordView(store: battleRecordStore)
      case let .contentActivity(contentActivityStore):
        ContentActivityView(store: contentActivityStore)
      case let .notice(noticeStore):
        NoticeView(store: noticeStore)
      case let .notificationSetting(notificationStore):
        NotificationSettingView(store: notificationStore)
      case let .withdraw(withdrawStore):
        WithdrawReasonView(store: withdrawStore)
      case let .battleProposal(battleProposalStore):
        BattleProposalView(store: battleProposalStore)
      case let .recap(recapStore):
        RecapView(store: recapStore)
      case let .notification(notificationStore):
        NotificationCoordinatorView(store: notificationStore)
          .toolbar(.hidden, for: .tabBar)
      case let .web(webStore):
        WebView(store: webStore)
      case let .chat(chatStore):
        ChatCoordinatorView(store: chatStore)
          .toolbar(.hidden, for: .tabBar)
      }
    }
  }
}
