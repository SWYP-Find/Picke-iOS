//
//  AppView.swift
//  Picke
//
//  Created by Wonji Suh  on 5/6/26.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem

import Presentation

struct AppView: View {
  @Bindable var store: StoreOf<AppReducer>

  var body: some View {
    ZStack(alignment: .topLeading) {
      Color.primary50
        .edgesIgnoringSafeArea(.all)

      SwitchStore(store) { state in
        switch state {
        case .splash:
          if let store = store.scope(state: \.splash, action: \.scope.splash) {
            SplashView(store: store)
              .transition(.opacity.combined(with: .scale(scale: 0.98)))
          }

        case .auth:
          if let store = store.scope(state: \.auth, action: \.scope.auth) {
            AuthCoordinatorView(store: store)
              .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
              ))
          }

        case .mainTab:
          if let store = store.scope(state: \.mainTab, action: \.scope.mainTab) {
            MainTabView(store: store)
              .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
              ))
          }
        }
      }
    }
    .toastOverlay()
    .animation(
      .spring(response: 0.52, dampingFraction: 0.94, blendDuration: 0.14),
      value: store.state.animationID
    )
    .onAppear {
      store.send(.async(.startNotificationListener))
    }
  }
}

#Preview {
  AppView(
    store: Store(
      initialState: AppReducer.State(),
      reducer: {
        AppReducer()
      }
    )
  )
}
