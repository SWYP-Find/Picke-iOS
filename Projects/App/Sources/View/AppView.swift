//
//  AppView.swift
//  Picke
//
//  Created by Wonji Suh  on 5/6/26.
//

import SwiftUI

import Splash
import ComposableArchitecture
import DesignSystem

struct AppView: View {
  @Bindable var store: StoreOf<AppReducer>
  
  var body: some View {
    ZStack(alignment: .topLeading) {
      Color.gray50
        .edgesIgnoringSafeArea(.all)
      
      SwitchStore(store) { state in
        switch state {
        case .splash:
          if let store = store.scope(state: \.splash, action: \.scope.splash) {
            SplashView(store: store)
              .transition(.opacity.combined(with: .scale(scale: 0.98)))
          }
          
        
        }
      }
    }
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
      })
  )
}

