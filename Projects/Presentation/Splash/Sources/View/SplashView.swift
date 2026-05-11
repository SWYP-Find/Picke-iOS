//
//  SplashView.swift
//  Splash
//
//  Created by Wonji Suh  on 5/6/26.
//

import SwiftUI
import ComposableArchitecture
import SDWebImageSwiftUI

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
        
        AnimatedImage(name: "splashLogo.gif", isAnimating: .constant(true))
          .resizable()                       // ← 추가
          .scaledToFit()                     // .aspectRatio(.fit) 과 동일, 더 짧음
          .frame(width: 250, height: 250)          
        
        Spacer()
      }
    }
    .onAppear {
      store.send(.view(.onAppear))
    }
  }
}
