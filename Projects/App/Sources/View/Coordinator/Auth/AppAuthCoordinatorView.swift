//
//  AppAuthCoordinatorView.swift
//  Picke
//

import SwiftUI

import ComposableArchitecture
import Presentation
import TCAFlow

public struct AppAuthCoordinatorView: View {
  @Bindable private var store: StoreOf<AppAuthCoordinator>

  public init(store: StoreOf<AppAuthCoordinator>) {
    self.store = store
  }

  public var body: some View {
    TCAFlowRouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
      case let .login(loginStore):
        LoginView(store: loginStore)
          .navigationBarBackButtonHidden()

      case let .onboarding(onboardingStore):
        OnBoardingView(store: onboardingStore)
          .navigationBarBackButtonHidden()

      case let .web(webStore):
        WebView(store: webStore)
          .navigationBarBackButtonHidden()
      }
    }
  }
}
