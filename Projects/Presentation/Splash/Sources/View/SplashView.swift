//
//  SplashView.swift
//  Splash
//
//  Created by Wonji Suh  on 5/6/26.
//

import SwiftUI
import ComposableArchitecture

import DesignSystem

public struct SplashView: View {
  @Bindable var store: StoreOf<SplashFeature>
  
  public init(
    store: StoreOf<SplashFeature>
  ) {
    self.store = store
  }
  
  
  public var body: some View {
    ZStack {
      Color.primary500
        .edgesIgnoringSafeArea(.all)
      
      VStack {
        
        Spacer()
        
        Image(asset: .splashLogo)
          .resizable()
          .scaledToFit()
          .frame(height: 203)
        
        Spacer()
      }
    }
  }
}
