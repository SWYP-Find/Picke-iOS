//
//  SplashView.swift
//  Splash
//
//  Created by Wonji Suh  on 5/6/26.
//

import ComposableArchitecture
import SwiftUI

import PickeDesignKit

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

        SplashLogoAnimation()
          .equatable()

        Spacer()
      }
    }
    .onAppear {
      store.send(.view(.onAppear))
    }
    .alert($store.scope(state: \.alert, action: \.alert))
  }
}

private struct SplashLogoAnimation: View, Equatable {
  static func == (_: Self, _: Self) -> Bool { true }

  var body: some View {
    SplashLogoAnimatedImageView()
  }
}
