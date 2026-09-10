//
//  NotificationCoordinatorView.swift
//  Picke
//

import SwiftUI

import ComposableArchitecture
import FeatureAssembly
import TCAFlow

public struct NotificationCoordinatorView: View {
  @Bindable private var store: StoreOf<NotificationCoordinator>

  public init(store: StoreOf<NotificationCoordinator>) {
    self.store = store
  }

  public var body: some View {
    TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
      case let .notification(notificationStore):
        NotificationView(store: notificationStore)
      }
    }
  }
}
