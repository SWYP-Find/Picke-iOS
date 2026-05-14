//
//  HomeCoordinatorView.swift
//  Home
//
//  Created by Wonji Suh on 5/15/26.
//

import Foundation

import SwiftUI

import ComposableArchitecture
import TCAFlow

public struct HomeCoordinatorView: View {
  @Bindable private var store: StoreOf<HomeCoordinator>

  public init(store: StoreOf<HomeCoordinator>) {
    self.store = store
  }

  public var body: some View {
    TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
      case let .home(homeStore):
        HomeView(store: homeStore)
      }
    }
  }
}
