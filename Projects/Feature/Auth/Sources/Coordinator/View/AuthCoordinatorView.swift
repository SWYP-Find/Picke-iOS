//
//  AuthCoordinatorView.swift
//  Auth
//
//  Created by Wonji Suh  on 5/11/26.
//

import Foundation

import SwiftUI

import ComposableArchitecture
import TCAFlow

public struct AuthCoordinatorView: View {
  @Bindable private var store: StoreOf<AuthCoordinator>

  public init(
    store: StoreOf<AuthCoordinator>
  ) {
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
      }
    }
  }
}
