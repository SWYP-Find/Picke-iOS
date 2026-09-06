//
//  HifiCoordinatorView.swift
//  Hifi
//

import Foundation

import SwiftUI

import ComposableArchitecture
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
      }
    }
  }
}
