//
//  AppView.swift
//  Picke
//
//  Created by Wonji Suh  on 5/6/26.
//

import SwiftUI

import ComposableArchitecture
import PickeDesignKit

import Presentation
import AdService

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
            AppAuthCoordinatorView(store: store)
              .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
              ))
          }

        case .mainTab:
          if let store = store.scope(state: \.mainTab, action: \.scope.mainTab) {
            AppMainTabView(store: store)
              .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
              ))
              // splash 가 아닌 메인 진입 시점이라 rootViewController 가 준비돼 있다.
              // 닫기 종류와 관계없이 다음 메인 진입 때 다시 요청한다.
              .onAppear {
                AppStartPopupAd.presentIfNeeded(
                  // 이 스코프의 store 는 mainTab 코디네이터라 루트 스토어를 명시한다.
                  onAdClick: { self.store.send(.view(.appStartAdClicked)) }
                )
              }
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
