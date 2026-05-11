//
//  AuthCoordinatorView.swift
//  Auth
//
//  Created by Wonji Suh  on 5/11/26.
//

import Foundation

import SwiftUI

import TCAFlow
import ComposableArchitecture


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
      case .login(let loginStore):
        LoginView(store: loginStore)
          .navigationBarBackButtonHidden()
        

      }
    }
  }
}
