//
//  ProfileCoordinatorView.swift
//  Profile
//

import Foundation

import SwiftUI

import ComposableArchitecture
import TCAFlow
import Web

public struct ProfileCoordinatorView: View {
  @Bindable private var store: StoreOf<ProfileCoordinator>

  public init(store: StoreOf<ProfileCoordinator>) {
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
      case let .web(webStore):
        WebView(store: webStore)
      }
    }
  }
}
