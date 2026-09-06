//
//  AppHomeCoordinatorView.swift
//  Picke
//

import SwiftUI

import ComposableArchitecture
import FeatureAssembly
import TCAFlow

public struct AppHomeCoordinatorView: View {
  @Bindable private var store: StoreOf<AppHomeCoordinator>

  public init(store: StoreOf<AppHomeCoordinator>) {
    self.store = store
  }

  public var body: some View {
    TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
      case let .home(homeStore):
        HomeView(store: homeStore)
      case let .chat(chatStore):
        ChatCoordinatorView(store: chatStore)
          .toolbar(.hidden, for: .tabBar)
      case let .notification(notificationStore):
        NotificationCoordinatorView(store: notificationStore)
          .toolbar(.hidden, for: .tabBar)
      }
    }
  }
}
