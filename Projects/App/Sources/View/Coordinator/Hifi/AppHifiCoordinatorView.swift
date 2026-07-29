//
//  AppHifiCoordinatorView.swift
//  Picke
//

import SwiftUI

import ComposableArchitecture
import Presentation
import TCAFlow

public struct AppHifiCoordinatorView: View {
  @Bindable private var store: StoreOf<AppHifiCoordinator>

  public init(store: StoreOf<AppHifiCoordinator>) {
    self.store = store
  }

  public var body: some View {
    TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
      case let .hifi(hifiStore):
        HifiView(store: hifiStore)
      case let .chat(chatStore):
        ChatCoordinatorView(store: chatStore)
      case let .notification(notificationStore):
        NotificationCoordinatorView(store: notificationStore)
          .toolbar(.hidden, for: .tabBar)
      }
    }
  }
}
