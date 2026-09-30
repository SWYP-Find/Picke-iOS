//
//  ClassCoordinatorView.swift
//  Picke
//

import SwiftUI

import ComposableArchitecture
import FeatureAssembly
import TCAFlow

public struct ClassCoordinatorView: View {
  @Bindable private var store: StoreOf<ClassCoordinator>

  public init(store: StoreOf<ClassCoordinator>) {
    self.store = store
  }

  public var body: some View {
    TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
      case let .intro(introStore):
        ClassIntroView(store: introStore)
      }
    }
  }
}
