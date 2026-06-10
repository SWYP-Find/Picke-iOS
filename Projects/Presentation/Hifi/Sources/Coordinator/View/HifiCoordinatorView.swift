//
//  HifiCoordinatorView.swift
//  Hifi
//

import Foundation

import SwiftUI

import Chat
import ComposableArchitecture
import Notification
import TCAFlow

public struct HifiCoordinatorView: View {
  @Bindable private var store: StoreOf<HifiCoordinator>

  public init(store: StoreOf<HifiCoordinator>) {
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
