//
//  LoginView.swift
//  Auth
//
//  Created by Wonji Suh  on 5/11/26.
//

import SwiftUI
import ComposableArchitecture

import DesignSystem

public struct LoginView : View {
  @Bindable var store: StoreOf<LoginFeature>
  
  
  
  public var body: some View {
    ZStack {
      Color.neutral50
        .edgesIgnoringSafeArea(.all)
    }
    
  }
}
